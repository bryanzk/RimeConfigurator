import Foundation
import Yams
import Combine
import SwiftUI

// MARK: - Color Model (RIME uses 0xAABBGGRR / 0xBBGGRR format)

struct RimeColor: Equatable {
    var rawValue: Int

    var red: Double { Double(rawValue & 0xFF) / 255.0 }
    var green: Double { Double((rawValue >> 8) & 0xFF) / 255.0 }
    var blue: Double { Double((rawValue >> 16) & 0xFF) / 255.0 }
    var alpha: Double {
        let a = (rawValue >> 24) & 0xFF
        return a == 0 ? 1.0 : Double(a) / 255.0
    }

    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    static func from(r: Double, g: Double, b: Double, a: Double = 1.0) -> RimeColor {
        let ri = Int(r * 255) & 0xFF
        let gi = Int(g * 255) & 0xFF
        let bi = Int(b * 255) & 0xFF
        let ai = a < 1.0 ? (Int(a * 255) & 0xFF) : 0
        let value = (ai << 24) | (bi << 16) | (gi << 8) | ri
        return RimeColor(rawValue: value)
    }

    var yamlHex: String { String(format: "0x%06X", rawValue & 0xFFFFFF) }

    static let clear = RimeColor(rawValue: 0x00000000)
}

// MARK: - Schema Model

struct SchemaItem: Identifiable, Equatable {
    var id: String
    var name: String
}

// MARK: - Color Scheme Model

struct RimeColorScheme: Identifiable {
    var id: String
    var name: String
    var author: String

    var backColor: RimeColor
    var borderColor: RimeColor
    var textColor: RimeColor
    var candidateTextColor: RimeColor
    var commentTextColor: RimeColor
    var labelColor: RimeColor
    var hilitedCandidateBackColor: RimeColor
    var hilitedCandidateTextColor: RimeColor
    var hilitedCommentTextColor: RimeColor
    var hilitedTextColor: RimeColor
}

// MARK: - Style Config

struct StyleConfig: Equatable {
    var colorScheme: String = "native"
    var fontFace: String = "PingFang SC"
    var fontPoint: Int = 16
    var labelFontFace: String = "PingFang SC"
    var labelFontPoint: Int = 12
    var candidateListLayout: String = "stacked"
    var textOrientation: String = "horizontal"
    var inlinePreedit: Bool = true
    var inlineCandidate: Bool = false
    var translucency: Bool = false
    var cornerRadius: Int = 7
    var hiliteCornerRadius: Int = 0
    var borderHeight: Int = 0
    var borderWidth: Int = 0
    var lineSpacing: Int = 5
    var spacing: Int = 8
    var shadowSize: Int = 0
    var showPaging: Bool = false
}

// MARK: - Behavior Config

struct BehaviorConfig: Equatable {
    var pageSize: Int = 9
}

// MARK: - App Override Model

struct AppOption: Identifiable, Equatable {
    var bundleID: String
    var appName: String? = nil
    var asciiMode: Bool = false
    var inlineMode: Bool = false
    var noInline: Bool = false
    var vimMode: Bool = false

    var id: String { bundleID }

    var displayTitle: String {
        appName?.isEmpty == false ? appName! : bundleID
    }
}

// MARK: - Diagnostics

enum ConfigDiagnosticKind: String {
    case error
    case warning
    case info
}

struct ConfigDiagnostic: Identifiable, Equatable {
    var kind: ConfigDiagnosticKind
    var message: String

    var id: String { "\(kind.rawValue)-\(message)" }
}

// MARK: - Deploy Feedback

enum DeployState: Equatable {
    case deployedAutomatically
    case deploymentRequested
    case manualActionRequired
}

struct DeployFeedback: Equatable {
    var state: DeployState
    var title: String
    var message: String
    var showsManualSteps: Bool

    static func infer(
        strings: AppStrings,
        beforeBuildDate: Date?,
        afterBuildDate: Date?,
        reloadAttempted: Bool,
        binaryAvailable: Bool
    ) -> DeployFeedback {
        if let afterBuildDate, beforeBuildDate == nil || afterBuildDate > beforeBuildDate! {
            return DeployFeedback(
                state: .deployedAutomatically,
                title: strings.deployAutoTitle,
                message: strings.deployAutoMessage,
                showsManualSteps: false
            )
        }

        if reloadAttempted || binaryAvailable {
            return DeployFeedback(
                state: .deploymentRequested,
                title: strings.deployRequestedTitle,
                message: strings.deployRequestedMessage,
                showsManualSteps: true
            )
        }

        return DeployFeedback(
            state: .manualActionRequired,
            title: strings.deployManualTitle,
            message: strings.deployManualMessage,
            showsManualSteps: true
        )
    }

    static func noop(strings: AppStrings) -> DeployFeedback {
        DeployFeedback(
            state: .manualActionRequired,
            title: strings.deployTestTitle,
            message: strings.deployTestMessage,
            showsManualSteps: false
        )
    }
}

@MainActor
struct DeployPerformer {
    let perform: @MainActor (_ rimeDir: URL, _ fileManager: FileManager, _ strings: AppStrings) async -> DeployFeedback

    static let noop = DeployPerformer { _, _, strings in
        .noop(strings: strings)
    }

    static let live = DeployPerformer { rimeDir, fileManager, strings in
        let beforeBuildDate = latestBuildDate(in: rimeDir, fileManager: fileManager)
        let squirrelBin = "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel"
        let binaryAvailable = fileManager.fileExists(atPath: squirrelBin)

        let center = DistributedNotificationCenter.default()
        center.post(name: Notification.Name("RimeSchemaSelectorUpdate"), object: "deploy")
        center.post(name: Notification.Name("RimeDeployAction"), object: nil)

        let installPath = rimeDir.appendingPathComponent("installation.yaml")
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: installPath.path)

        var reloadAttempted = false
        if binaryAvailable {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: squirrelBin)
            process.arguments = ["--reload"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            if (try? process.run()) != nil {
                reloadAttempted = true
            }
        }

        try? await Task.sleep(nanoseconds: 1_200_000_000)
        let afterBuildDate = latestBuildDate(in: rimeDir, fileManager: fileManager)

        return DeployFeedback.infer(
            strings: strings,
            beforeBuildDate: beforeBuildDate,
            afterBuildDate: afterBuildDate,
            reloadAttempted: reloadAttempted,
            binaryAvailable: binaryAvailable
        )
    }

    private static func latestBuildDate(in rimeDir: URL, fileManager: FileManager) -> Date? {
        let buildDir = rimeDir.appendingPathComponent("build")
        guard let files = try? fileManager.contentsOfDirectory(
            at: buildDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        return files.compactMap { url in
            try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        }.max()
    }
}

private struct ConfigSnapshot: Equatable {
    var enabledSchemas: [SchemaItem]
    var style: StyleConfig
    var behavior: BehaviorConfig
    var appOptions: [AppOption]
}

private enum SchemaListLoadResult {
    case missing
    case found([SchemaItem])
}

// MARK: - Config Manager

@MainActor
class ConfigManager: ObservableObject {
    static let languageDefaultsKey = "appLanguage"

    @Published var availableSchemas: [SchemaItem] = []
    @Published var enabledSchemas: [SchemaItem] = []
    @Published var style = StyleConfig()
    @Published var behavior = BehaviorConfig()
    @Published var appOptions: [AppOption] = []
    @Published var colorSchemes: [RimeColorScheme] = []
    @Published var language: AppLanguage = .simplifiedChineseChina
    @Published var statusMessage: String = ""
    @Published var diagnostics: [ConfigDiagnostic] = []
    @Published var isLoaded: Bool = false
    @Published var lastSavedSquirrelYAML: String = ""
    @Published var lastSavedDefaultYAML: String = ""
    @Published var lastDeployFeedback: DeployFeedback?

    let rimeDir: URL
    let sharedSupportDir: URL

    private let fileManager: FileManager
    private let userDefaults: UserDefaults
    private let deployPerformer: DeployPerformer
    private var loadedSnapshot = ConfigSnapshot(
        enabledSchemas: [],
        style: StyleConfig(),
        behavior: BehaviorConfig(),
        appOptions: []
    )

    init(
        rimeDir: URL? = nil,
        sharedSupportDir: URL? = nil,
        fileManager: FileManager = .default,
        userDefaults: UserDefaults = .standard,
        deployPerformer: DeployPerformer? = nil
    ) {
        self.fileManager = fileManager
        self.userDefaults = userDefaults
        self.deployPerformer = deployPerformer ?? .live
        self.rimeDir = rimeDir ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Rime")
        self.sharedSupportDir = sharedSupportDir ?? URL(fileURLWithPath: "/Library/Input Methods/Squirrel.app/Contents/SharedSupport")
    }

    var strings: AppStrings {
        AppStrings(language: language)
    }

    var hasUnsavedChanges: Bool {
        currentSnapshot != loadedSnapshot
    }

    var currentColorScheme: RimeColorScheme? {
        colorSchemes.first { $0.id == style.colorScheme }
    }

    var disabledSchemas: [SchemaItem] {
        availableSchemas.filter { schema in
            !enabledSchemas.contains(where: { $0.id == schema.id })
        }
    }

    var primaryDiagnostic: ConfigDiagnostic? {
        diagnostics.sorted { severity(of: $0.kind) > severity(of: $1.kind) }.first
    }

    func loadConfig() {
        loadLanguagePreference()
        resetEditableState()
        loadColorSchemes()
        loadAvailableSchemas()
        loadEnabledSchemas()
        loadStyleConfig()
        loadBehaviorConfig()
        sortAppOptions()
        refreshDiagnostics()
        loadedSnapshot = currentSnapshot
        isLoaded = true
        statusMessage = diagnostics.isEmpty ? strings.diagnosticsLoaded : strings.diagnosticsCount(diagnostics.count)
    }

    func discardChanges() {
        loadConfig()
    }

    func resetAppearanceDefaults() {
        style = StyleConfig()
    }

    func resetBehaviorDefaults() {
        behavior = BehaviorConfig()
        appOptions = []
        let defaults = StyleConfig()
        style.inlinePreedit = defaults.inlinePreedit
        style.inlineCandidate = defaults.inlineCandidate
        style.translucency = defaults.translucency
        style.showPaging = defaults.showPaging
    }

    func setLanguage(_ language: AppLanguage) {
        guard self.language != language else { return }
        self.language = language
        userDefaults.set(language.rawValue, forKey: Self.languageDefaultsKey)
        if isLoaded {
            refreshDiagnostics()
            statusMessage = diagnostics.isEmpty ? strings.diagnosticsLoaded : strings.diagnosticsCount(diagnostics.count)
        }
    }

    func addAppOption(bundleID: String) {
        let normalized = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        guard !appOptions.contains(where: { $0.bundleID == normalized }) else { return }
        appOptions.append(AppOption(bundleID: normalized))
        sortAppOptions()
    }

    func addAppOption(descriptor: AppBundleDescriptor) {
        if let index = appOptions.firstIndex(where: { $0.bundleID == descriptor.bundleID }) {
            appOptions[index].appName = descriptor.displayName
        } else {
            appOptions.append(AppOption(bundleID: descriptor.bundleID, appName: descriptor.displayName))
            sortAppOptions()
        }
    }

    func removeAppOption(_ option: AppOption) {
        appOptions.removeAll { $0.bundleID == option.bundleID }
    }

    func enableSchema(_ schema: SchemaItem) {
        guard !enabledSchemas.contains(where: { $0.id == schema.id }) else { return }
        enabledSchemas.append(schema)
    }

    func disableSchema(_ schema: SchemaItem) {
        enabledSchemas.removeAll { $0.id == schema.id }
    }

    func moveSchema(fromOffsets: IndexSet, toOffset: Int) {
        enabledSchemas.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    func saveConfig() throws {
        try createRimeDirIfNeeded()
        try saveSquirrelCustom()
        try saveDefaultCustom()
        refreshDiagnostics()
        loadedSnapshot = currentSnapshot
        statusMessage = strings.configurationSaved
    }

    func saveAndDeploy() async throws -> DeployFeedback {
        try saveConfig()
        let feedback = await deployPerformer.perform(rimeDir, fileManager, strings)
        lastDeployFeedback = feedback
        return feedback
    }

    private var currentSnapshot: ConfigSnapshot {
        ConfigSnapshot(
            enabledSchemas: enabledSchemas,
            style: style,
            behavior: behavior,
            appOptions: appOptions
        )
    }

    private func resetEditableState() {
        enabledSchemas = []
        style = StyleConfig()
        behavior = BehaviorConfig()
        appOptions = []
        lastDeployFeedback = nil
    }

    private func refreshDiagnostics() {
        var items: [ConfigDiagnostic] = []

        if !fileManager.fileExists(atPath: sharedSupportDir.path) {
            items.append(ConfigDiagnostic(
                kind: .error,
                message: strings.missingSharedSupport(sharedSupportDir.path)
            ))
        }

        if !fileManager.fileExists(atPath: rimeDir.path) {
            items.append(ConfigDiagnostic(
                kind: .warning,
                message: strings.missingRimeDir(rimeDir.path)
            ))
        }

        if availableSchemas.isEmpty {
            items.append(ConfigDiagnostic(
                kind: .warning,
                message: strings.noAvailableSchemasDiagnostic(sharedSupportPath: sharedSupportDir.path, rimePath: rimeDir.path)
            ))
        }

        if enabledSchemas.isEmpty {
            items.append(ConfigDiagnostic(
                kind: .info,
                message: strings.noEnabledSchemasDiagnostic
            ))
        }

        diagnostics = items
    }

    private func severity(of kind: ConfigDiagnosticKind) -> Int {
        switch kind {
        case .error: return 3
        case .warning: return 2
        case .info: return 1
        }
    }

    // MARK: - Load

    private func loadColorSchemes() {
        let searchPaths = [
            rimeDir.appendingPathComponent("squirrel.yaml"),
            sharedSupportDir.appendingPathComponent("squirrel.yaml"),
            rimeDir.appendingPathComponent("build/squirrel.yaml")
        ]

        for path in searchPaths {
            if let content = try? String(contentsOf: path, encoding: .utf8),
               let yaml = try? Yams.load(yaml: content) as? [String: Any] {
                let schemesDict = yaml["preset_color_schemes"] as? [String: Any]
                    ?? yaml["color_schemes"] as? [String: Any]
                    ?? [:]
                colorSchemes = schemesDict.compactMap { key, value in
                    guard let dict = value as? [String: Any] else { return nil }
                    return parseColorScheme(id: key, dict: dict)
                }.sorted { $0.name < $1.name }
                if !colorSchemes.isEmpty {
                    break
                }
            }
        }

        if colorSchemes.isEmpty {
            colorSchemes = Self.fallbackSchemes
        }
    }

    private func loadLanguagePreference() {
        guard let rawValue = userDefaults.string(forKey: Self.languageDefaultsKey),
              let storedLanguage = AppLanguage(rawValue: rawValue) else {
            language = .simplifiedChineseChina
            return
        }
        language = storedLanguage
    }

    private func parseColorScheme(id: String, dict: [String: Any]) -> RimeColorScheme {
        func color(_ key: String) -> RimeColor {
            if let value = dict[key] {
                if let intValue = value as? Int {
                    return RimeColor(rawValue: intValue)
                }
                if let stringValue = value as? String,
                   stringValue.hasPrefix("0x") || stringValue.hasPrefix("0X"),
                   let intValue = Int(stringValue.dropFirst(2), radix: 16) {
                    return RimeColor(rawValue: intValue)
                }
            }
            return .clear
        }

        return RimeColorScheme(
            id: id,
            name: dict["name"] as? String ?? id,
            author: dict["author"] as? String ?? "",
            backColor: color("back_color"),
            borderColor: color("border_color"),
            textColor: color("text_color"),
            candidateTextColor: color("candidate_text_color"),
            commentTextColor: color("comment_text_color"),
            labelColor: color("label_color"),
            hilitedCandidateBackColor: color("hilited_candidate_back_color"),
            hilitedCandidateTextColor: color("hilited_candidate_text_color"),
            hilitedCommentTextColor: color("hilited_comment_text_color"),
            hilitedTextColor: color("hilited_text_color")
        )
    }

    private func loadAvailableSchemas() {
        var schemas: [SchemaItem] = []
        for dir in [rimeDir, sharedSupportDir] {
            let files = (try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
            for file in files where file.lastPathComponent.hasSuffix(".schema.yaml") {
                if let item = parseSchemaFile(file),
                   !schemas.contains(where: { $0.id == item.id }) {
                    schemas.append(item)
                }
            }
        }
        availableSchemas = schemas.sorted { $0.name < $1.name }
    }

    private func parseSchemaFile(_ url: URL) -> SchemaItem? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        var inSchema = false
        var schemaID: String?
        var schemaName: String?

        for line in content.split(separator: "\n", omittingEmptySubsequences: false) {
            let raw = String(line)
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed == "schema:" {
                inSchema = true
                continue
            }
            if inSchema {
                if trimmed.hasPrefix("schema_id:") {
                    schemaID = sanitizeScalar(String(trimmed.dropFirst("schema_id:".count)))
                } else if trimmed.hasPrefix("name:") {
                    schemaName = sanitizeScalar(String(trimmed.dropFirst("name:".count)))
                } else if !trimmed.isEmpty && !trimmed.hasPrefix("#") && !raw.hasPrefix("  ") && !raw.hasPrefix("\t") {
                    break
                }
            }
        }

        guard let schemaID, !schemaID.isEmpty else { return nil }
        return SchemaItem(id: schemaID, name: schemaName ?? schemaID)
    }

    private func loadEnabledSchemas() {
        let customPath = rimeDir.appendingPathComponent("default.custom.yaml")
        let defaultPath = rimeDir.appendingPathComponent("default.yaml")
        let builtinPath = sharedSupportDir.appendingPathComponent("default.yaml")

        if case .found(let list) = parseSchemaList(from: customPath, key: "patch/schema_list") {
            enabledSchemas = list
            return
        }
        if case .found(let list) = parseSchemaList(from: defaultPath, key: "schema_list") {
            enabledSchemas = list
            return
        }
        if case .found(let list) = parseSchemaList(from: builtinPath, key: "schema_list") {
            enabledSchemas = list
        }
    }

    private func parseSchemaList(from url: URL, key: String) -> SchemaListLoadResult {
        guard let content = try? String(contentsOf: url, encoding: .utf8),
              let yaml = try? Yams.load(yaml: content) as? [String: Any] else {
            return .missing
        }

        var node: Any? = yaml
        for part in key.split(separator: "/") {
            node = (node as? [String: Any])?[String(part)]
        }
        guard let list = node as? [[String: Any]] else {
            return .missing
        }

        return .found(list.compactMap { item in
            guard let id = item["schema"] as? String else { return nil }
            let name = item["name"] as? String
                ?? availableSchemas.first(where: { $0.id == id })?.name
                ?? id
            return SchemaItem(id: id, name: name)
        })
    }

    private func loadStyleConfig() {
        for path in [
            rimeDir.appendingPathComponent("squirrel.custom.yaml"),
            rimeDir.appendingPathComponent("squirrel.custom.yam")
        ] {
            if let content = try? String(contentsOf: path, encoding: .utf8),
               let yaml = try? Yams.load(yaml: content) as? [String: Any],
               let patch = yaml["patch"] as? [String: Any] {
                let styleDict = patch["style"] as? [String: Any] ?? [:]
                applyStyleDict(styleDict, patch: patch)
                appOptions = parseAppOptions(from: patch)
                break
            }
        }
    }

    private func applyStyleDict(_ styleDict: [String: Any], patch: [String: Any]) {
        func stringValue(_ key: String) -> String? {
            (styleDict[key] as? String) ?? (patch["style/\(key)"] as? String)
        }

        func intValue(_ key: String) -> Int? {
            (styleDict[key] as? Int) ?? (patch["style/\(key)"] as? Int)
        }

        func boolValue(_ key: String) -> Bool? {
            if let value = styleDict[key] as? Bool ?? patch["style/\(key)"] as? Bool {
                return value
            }
            return nil
        }

        if let value = stringValue("color_scheme") { style.colorScheme = value }
        if let value = stringValue("font_face") { style.fontFace = value }
        if let value = intValue("font_point") { style.fontPoint = value }
        if let value = stringValue("label_font_face") { style.labelFontFace = value }
        if let value = intValue("label_font_point") { style.labelFontPoint = value }
        if let value = stringValue("candidate_list_layout") { style.candidateListLayout = value }
        if let value = stringValue("text_orientation") { style.textOrientation = value }
        if let value = boolValue("inline_preedit") { style.inlinePreedit = value }
        if let value = boolValue("inline_candidate") { style.inlineCandidate = value }
        if let value = boolValue("translucency") { style.translucency = value }
        if let value = intValue("corner_radius") { style.cornerRadius = value }
        if let value = intValue("hilited_corner_radius") { style.hiliteCornerRadius = value }
        if let value = intValue("border_height") { style.borderHeight = value }
        if let value = intValue("border_width") { style.borderWidth = value }
        if let value = intValue("line_spacing") { style.lineSpacing = value }
        if let value = intValue("spacing") { style.spacing = value }
        if let value = intValue("shadow_size") { style.shadowSize = value }
        if let value = boolValue("show_paging") { style.showPaging = value }
    }

    private func parseAppOptions(from patch: [String: Any]) -> [AppOption] {
        var mapped: [String: AppOption] = [:]

        if let nested = patch["app_options"] as? [String: Any] {
            for (bundleID, rawValue) in nested {
                guard let dict = rawValue as? [String: Any] else { continue }
                var option = mapped[bundleID] ?? AppOption(bundleID: bundleID)
                applyAppFlags(from: dict, to: &option)
                mapped[bundleID] = option
            }
        }

        for (key, rawValue) in patch {
            guard key.hasPrefix("app_options/") else { continue }
            let suffix = String(key.dropFirst("app_options/".count))
            let parts = suffix.split(separator: "/", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            var option = mapped[parts[0]] ?? AppOption(bundleID: parts[0])
            setAppFlag(named: parts[1], value: rawValue, on: &option)
            mapped[parts[0]] = option
        }

        return mapped.values.sorted { $0.bundleID.localizedStandardCompare($1.bundleID) == .orderedAscending }
    }

    private func applyAppFlags(from dict: [String: Any], to option: inout AppOption) {
        for (key, value) in dict {
            setAppFlag(named: key, value: value, on: &option)
        }
    }

    private func setAppFlag(named key: String, value: Any, on option: inout AppOption) {
        let boolValue: Bool?
        if let direct = value as? Bool {
            boolValue = direct
        } else if let intValue = value as? Int {
            boolValue = intValue != 0
        } else if let stringValue = value as? String {
            boolValue = ["1", "true", "yes", "on"].contains(stringValue.lowercased())
        } else {
            boolValue = nil
        }

        guard let boolValue else { return }
        switch key {
        case "ascii_mode":
            option.asciiMode = boolValue
        case "inline":
            option.inlineMode = boolValue
        case "no_inline":
            option.noInline = boolValue
        case "vim_mode":
            option.vimMode = boolValue
        default:
            break
        }
    }

    private func loadBehaviorConfig() {
        let path = rimeDir.appendingPathComponent("default.custom.yaml")
        guard let content = try? String(contentsOf: path, encoding: .utf8),
              let yaml = try? Yams.load(yaml: content) as? [String: Any],
              let patch = yaml["patch"] as? [String: Any] else {
            return
        }

        if let menu = patch["menu"] as? [String: Any],
           let pageSize = menu["page_size"] as? Int {
            behavior.pageSize = pageSize
        }
        if let pageSize = patch["menu/page_size"] as? Int {
            behavior.pageSize = pageSize
        }
    }

    // MARK: - Save

    private func createRimeDirIfNeeded() throws {
        if !fileManager.fileExists(atPath: rimeDir.path) {
            try fileManager.createDirectory(at: rimeDir, withIntermediateDirectories: true)
        }
    }

    private func saveSquirrelCustom() throws {
        var root = loadYAMLDictionary(from: rimeDir.appendingPathComponent("squirrel.custom.yaml"))
        var patch = root["patch"] as? [String: Any] ?? [:]

        patch.removeValue(forKey: "style")
        patch.removeValue(forKey: "app_options")
        removeManagedPatchKeys(from: &patch, prefix: "style/")
        removeManagedPatchKeys(from: &patch, prefix: "app_options/")

        patch["style"] = buildStyleDictionary()
        if !appOptions.isEmpty {
            patch["app_options"] = buildAppOptionsDictionary()
        }

        root["patch"] = patch
        let yaml = try dumpYAML(root)
        lastSavedSquirrelYAML = yaml
        try yaml.write(
            to: rimeDir.appendingPathComponent("squirrel.custom.yaml"),
            atomically: true,
            encoding: .utf8
        )
    }

    private func saveDefaultCustom() throws {
        var root = loadYAMLDictionary(from: rimeDir.appendingPathComponent("default.custom.yaml"))
        var patch = root["patch"] as? [String: Any] ?? [:]

        patch.removeValue(forKey: "menu")
        patch.removeValue(forKey: "schema_list")
        removeManagedPatchKeys(from: &patch, prefix: "menu/")

        patch["menu"] = ["page_size": behavior.pageSize]
        patch["schema_list"] = enabledSchemas.map { item in
            [
                "schema": item.id,
                "name": item.name
            ]
        }

        root["patch"] = patch
        let output = try dumpYAML(root)
        lastSavedDefaultYAML = output
        try output.write(
            to: rimeDir.appendingPathComponent("default.custom.yaml"),
            atomically: true,
            encoding: .utf8
        )
    }

    private func sanitizeScalar(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private func sortAppOptions() {
        appOptions.sort { $0.bundleID.localizedStandardCompare($1.bundleID) == .orderedAscending }
    }

    private func loadYAMLDictionary(from url: URL) -> [String: Any] {
        guard let content = try? String(contentsOf: url, encoding: .utf8),
              let yaml = try? Yams.load(yaml: content) as? [String: Any] else {
            return [:]
        }
        return yaml
    }

    private func removeManagedPatchKeys(from patch: inout [String: Any], prefix: String) {
        for key in patch.keys where key.hasPrefix(prefix) {
            patch.removeValue(forKey: key)
        }
    }

    private func buildStyleDictionary() -> [String: Any] {
        [
            "color_scheme": style.colorScheme,
            "font_face": style.fontFace,
            "font_point": style.fontPoint,
            "label_font_face": style.labelFontFace,
            "label_font_point": style.labelFontPoint,
            "candidate_list_layout": style.candidateListLayout,
            "text_orientation": style.textOrientation,
            "inline_preedit": style.inlinePreedit,
            "inline_candidate": style.inlineCandidate,
            "translucency": style.translucency,
            "corner_radius": style.cornerRadius,
            "hilited_corner_radius": style.hiliteCornerRadius,
            "border_height": style.borderHeight,
            "border_width": style.borderWidth,
            "line_spacing": style.lineSpacing,
            "spacing": style.spacing,
            "shadow_size": style.shadowSize,
            "show_paging": style.showPaging
        ]
    }

    private func buildAppOptionsDictionary() -> [String: Any] {
        var result: [String: Any] = [:]
        for option in appOptions.sorted(by: { $0.bundleID.localizedStandardCompare($1.bundleID) == .orderedAscending }) {
            result[option.bundleID] = [
                "ascii_mode": option.asciiMode,
                "inline": option.inlineMode,
                "no_inline": option.noInline,
                "vim_mode": option.vimMode
            ]
        }
        return result
    }

    private func dumpYAML(_ dictionary: [String: Any]) throws -> String {
        let yaml = try Yams.dump(object: dictionary, sortKeys: true)
        return yaml.hasSuffix("\n") ? yaml : yaml + "\n"
    }

    // MARK: - Fallback Schemes

    static let fallbackSchemes: [RimeColorScheme] = [
        RimeColorScheme(
            id: "native",
            name: "系统原生／Native",
            author: "Squirrel",
            backColor: RimeColor(rawValue: 0xFFFFFF),
            borderColor: RimeColor(rawValue: 0xCCCCCC),
            textColor: RimeColor(rawValue: 0x000000),
            candidateTextColor: RimeColor(rawValue: 0x000000),
            commentTextColor: RimeColor(rawValue: 0x999999),
            labelColor: RimeColor(rawValue: 0x888888),
            hilitedCandidateBackColor: RimeColor(rawValue: 0xCCE8FF),
            hilitedCandidateTextColor: RimeColor(rawValue: 0x000000),
            hilitedCommentTextColor: RimeColor(rawValue: 0x777777),
            hilitedTextColor: RimeColor(rawValue: 0x000000)
        ),
        RimeColorScheme(
            id: "luna",
            name: "明月／Luna",
            author: "佛振",
            backColor: RimeColor(rawValue: 0xF3F3EC),
            borderColor: RimeColor(rawValue: 0xE0E0D5),
            textColor: RimeColor(rawValue: 0x5A4A2F),
            candidateTextColor: RimeColor(rawValue: 0x5A4A2F),
            commentTextColor: RimeColor(rawValue: 0x999999),
            labelColor: RimeColor(rawValue: 0xBBAA88),
            hilitedCandidateBackColor: RimeColor(rawValue: 0xCDA76E),
            hilitedCandidateTextColor: RimeColor(rawValue: 0xFFFFFF),
            hilitedCommentTextColor: RimeColor(rawValue: 0xF0DFC8),
            hilitedTextColor: RimeColor(rawValue: 0x5A4A2F)
        )
    ]
}
