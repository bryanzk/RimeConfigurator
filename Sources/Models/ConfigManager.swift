import Foundation
import Yams
import Combine
import SwiftUI

// MARK: - Color Model (RIME uses 0xAABBGGRR / 0xBBGGRR format)

struct RimeColor: Equatable {
    var rawValue: Int  // stored as ABGR (or BGR)

    // Convert RIME BGR → RGB components
    var red:   Double { Double(rawValue & 0xFF)         / 255.0 }
    var green: Double { Double((rawValue >> 8)  & 0xFF) / 255.0 }
    var blue:  Double { Double((rawValue >> 16) & 0xFF) / 255.0 }
    var alpha: Double {
        let a = (rawValue >> 24) & 0xFF
        return a == 0 ? 1.0 : Double(a) / 255.0
    }

    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Create from SwiftUI Color's RGB values (not macOS system colors)
    static func from(r: Double, g: Double, b: Double, a: Double = 1.0) -> RimeColor {
        let ri = Int(r * 255) & 0xFF
        let gi = Int(g * 255) & 0xFF
        let bi = Int(b * 255) & 0xFF
        let ai = a < 1.0 ? (Int(a * 255) & 0xFF) : 0
        let value = (ai << 24) | (bi << 16) | (gi << 8) | ri
        return RimeColor(rawValue: value)
    }

    /// Human-readable hex for YAML output
    var yamlHex: String { String(format: "0x%06X", rawValue & 0xFFFFFF) }

    static let black = RimeColor(rawValue: 0x000000)
    static let white = RimeColor(rawValue: 0xFFFFFF)
    static let clear = RimeColor(rawValue: 0x00000000)
}

// MARK: - Schema Model

struct SchemaItem: Identifiable, Equatable {
    var id: String       // schema_id, e.g. "luna_pinyin"
    var name: String     // display name, e.g. "朙月拼音"
}

// MARK: - Color Scheme Model

struct RimeColorScheme: Identifiable {
    var id: String       // key in preset_color_schemes
    var name: String
    var author: String

    var backColor:                  RimeColor
    var borderColor:                RimeColor
    var textColor:                  RimeColor
    var candidateTextColor:         RimeColor
    var commentTextColor:           RimeColor
    var labelColor:                 RimeColor
    var hilitedCandidateBackColor:  RimeColor
    var hilitedCandidateTextColor:  RimeColor
    var hilitedCommentTextColor:    RimeColor
    var hilitedTextColor:           RimeColor
}

// MARK: - Style Config

struct StyleConfig {
    var colorScheme:          String = "native"
    var fontFace:             String = "PingFang SC"
    var fontPoint:            Int    = 16
    var labelFontFace:        String = "PingFang SC"
    var labelFontPoint:       Int    = 12
    var candidateListLayout:  String = "stacked"   // "stacked" | "linear"
    var textOrientation:      String = "horizontal" // "horizontal" | "vertical"
    var inlinePreedit:        Bool   = true
    var inlineCandidate:      Bool   = false
    var translucency:         Bool   = false
    var cornerRadius:         Int    = 7
    var hiliteCornerRadius:   Int    = 0
    var borderHeight:         Int    = 0
    var borderWidth:          Int    = 0
    var lineSpacing:          Int    = 5
    var spacing:              Int    = 8
    var shadowSize:           Int    = 0
    var showPaging:           Bool   = false
}

// MARK: - Behavior Config

struct BehaviorConfig {
    var pageSize: Int = 9
}

// MARK: - Config Manager

@MainActor
class ConfigManager: ObservableObject {

    // Discovered schemas (from SharedSupport + ~/Library/Rime)
    @Published var availableSchemas: [SchemaItem] = []
    // Currently enabled schemas (in order as they appear in schema_list)
    @Published var enabledSchemas:  [SchemaItem] = []
    // Style settings
    @Published var style    = StyleConfig()
    // Behavior settings
    @Published var behavior = BehaviorConfig()
    // Parsed color schemes from squirrel.yaml
    @Published var colorSchemes: [RimeColorScheme] = []
    // Status messages for the toolbar
    @Published var statusMessage: String = ""
    @Published var isLoaded: Bool = false

    let rimeDir: URL
    let sharedSupportDir: URL

    init() {
        rimeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Rime")
        sharedSupportDir = URL(fileURLWithPath:
            "/Library/Input Methods/Squirrel.app/Contents/SharedSupport")
    }

    // MARK: - Load

    func loadConfig() {
        loadColorSchemes()
        loadAvailableSchemas()
        loadEnabledSchemas()
        loadStyleConfig()
        loadBehaviorConfig()
        isLoaded = true
    }

    private func loadColorSchemes() {
        let searchPaths = [
            rimeDir.appendingPathComponent("squirrel.yaml"),
            sharedSupportDir.appendingPathComponent("squirrel.yaml"),
            rimeDir.appendingPathComponent("build/squirrel.yaml")
        ]
        for path in searchPaths {
            if let content = try? String(contentsOf: path, encoding: .utf8),
               let yaml = try? Yams.load(yaml: content) as? [String: Any] {
                // Squirrel 1.x uses "preset_color_schemes"
                let schemesDict = yaml["preset_color_schemes"] as? [String: Any]
                    ?? yaml["color_schemes"] as? [String: Any]
                    ?? [:]
                colorSchemes = schemesDict.compactMap { (key, value) in
                    guard let d = value as? [String: Any] else { return nil }
                    return parseColorScheme(id: key, dict: d)
                }.sorted { $0.name < $1.name }
                if !colorSchemes.isEmpty { break }
            }
        }
        // Fallback built-ins
        if colorSchemes.isEmpty { colorSchemes = Self.fallbackSchemes }
    }

    private func parseColorScheme(id: String, dict: [String: Any]) -> RimeColorScheme {
        func c(_ key: String) -> RimeColor {
            if let v = dict[key] {
                if let i = v as? Int   { return RimeColor(rawValue: i) }
                if let s = v as? String, s.hasPrefix("0x") || s.hasPrefix("0X"),
                   let i = Int(s.dropFirst(2), radix: 16) { return RimeColor(rawValue: i) }
            }
            return .clear
        }
        return RimeColorScheme(
            id:                         id,
            name:                       dict["name"] as? String ?? id,
            author:                     dict["author"] as? String ?? "",
            backColor:                  c("back_color"),
            borderColor:                c("border_color"),
            textColor:                  c("text_color"),
            candidateTextColor:         c("candidate_text_color"),
            commentTextColor:           c("comment_text_color"),
            labelColor:                 c("label_color"),
            hilitedCandidateBackColor:  c("hilited_candidate_back_color"),
            hilitedCandidateTextColor:  c("hilited_candidate_text_color"),
            hilitedCommentTextColor:    c("hilited_comment_text_color"),
            hilitedTextColor:           c("hilited_text_color")
        )
    }

    private func loadAvailableSchemas() {
        var schemas: [SchemaItem] = []
        let searchDirs = [rimeDir, sharedSupportDir]
        for dir in searchDirs {
            let files = (try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil)) ?? []
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
        var schemaId: String?
        var schemaName: String?
        for line in content.split(separator: "\n", omittingEmptySubsequences: false) {
            let s = String(line)
            let trimmed = s.trimmingCharacters(in: .whitespaces)
            if trimmed == "schema:" { inSchema = true; continue }
            if inSchema {
                if trimmed.hasPrefix("schema_id:") {
                    schemaId = trimmed.dropFirst("schema_id:".count)
                        .trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                } else if trimmed.hasPrefix("name:") {
                    schemaName = trimmed.dropFirst("name:".count)
                        .trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                } else if !trimmed.isEmpty && !trimmed.hasPrefix("#")
                    && !s.hasPrefix("  ") && !s.hasPrefix("\t") {
                    break
                }
            }
        }
        guard let id = schemaId, !id.isEmpty else { return nil }
        return SchemaItem(id: id, name: schemaName ?? id)
    }

    private func loadEnabledSchemas() {
        // Try user custom first, then default.yaml in Rime dir, then SharedSupport
        let customPath  = rimeDir.appendingPathComponent("default.custom.yaml")
        let defaultPath = rimeDir.appendingPathComponent("default.yaml")
        let builtinPath = sharedSupportDir.appendingPathComponent("default.yaml")

        if let list = parseSchemaList(from: customPath, key: "patch/schema_list"), !list.isEmpty {
            enabledSchemas = list; return
        }
        if let list = parseSchemaList(from: defaultPath, key: "schema_list"), !list.isEmpty {
            enabledSchemas = list; return
        }
        if let list = parseSchemaList(from: builtinPath, key: "schema_list"), !list.isEmpty {
            enabledSchemas = list; return
        }
        enabledSchemas = []
    }

    private func parseSchemaList(from url: URL, key: String) -> [SchemaItem]? {
        guard let content = try? String(contentsOf: url, encoding: .utf8),
              let yaml = try? Yams.load(yaml: content) as? [String: Any] else { return nil }

        var node: Any? = yaml
        for part in key.split(separator: "/") {
            node = (node as? [String: Any])?[String(part)]
        }
        guard let list = node as? [[String: Any]], !list.isEmpty else { return nil }
        return list.compactMap { item -> SchemaItem? in
            guard let id = item["schema"] as? String else { return nil }
            // Try to get name from available schemas, fall back to dict or id
            let name = item["name"] as? String
                ?? availableSchemas.first(where: { $0.id == id })?.name
                ?? id
            return SchemaItem(id: id, name: name)
        }
    }

    private func loadStyleConfig() {
        // Read from squirrel.custom.yaml (also handle ".yam" typo)
        let paths = [
            rimeDir.appendingPathComponent("squirrel.custom.yaml"),
            rimeDir.appendingPathComponent("squirrel.custom.yam")
        ]
        for path in paths {
            if let content = try? String(contentsOf: path, encoding: .utf8),
               let yaml = try? Yams.load(yaml: content) as? [String: Any],
               let patch = yaml["patch"] as? [String: Any] {
                let styleDict = patch["style"] as? [String: Any] ?? [:]
                applyStyleDict(styleDict, patch: patch)
                break
            }
        }
    }

    private func applyStyleDict(_ d: [String: Any], patch: [String: Any]) {
        func str(_ key: String)  -> String? { d[key] as? String }
        func int(_ key: String)  -> Int?    { d[key] as? Int }
        func bool(_ key: String) -> Bool?   { d[key] as? Bool }

        if let v = str("color_scheme")         { style.colorScheme = v }
        if let v = str("font_face")             { style.fontFace = v }
        if let v = int("font_point")            { style.fontPoint = v }
        if let v = str("label_font_face")       { style.labelFontFace = v }
        if let v = int("label_font_point")      { style.labelFontPoint = v }
        if let v = str("candidate_list_layout") { style.candidateListLayout = v }
        if let v = str("text_orientation")      { style.textOrientation = v }
        if let v = bool("inline_preedit")       { style.inlinePreedit = v }
        if let v = bool("inline_candidate")     { style.inlineCandidate = v }
        if let v = bool("translucency")         { style.translucency = v }
        if let v = int("corner_radius")         { style.cornerRadius = v }
        if let v = int("hilited_corner_radius") { style.hiliteCornerRadius = v }
        if let v = int("border_height")         { style.borderHeight = v }
        if let v = int("border_width")          { style.borderWidth = v }
        if let v = int("line_spacing")          { style.lineSpacing = v }
        if let v = int("spacing")               { style.spacing = v }
        if let v = int("shadow_size")           { style.shadowSize = v }
        if let v = bool("show_paging")          { style.showPaging = v }

        // Also handle flat patch keys like "style/color_scheme"
        for (key, val) in patch {
            if key == "style/color_scheme",   let v = val as? String { style.colorScheme = v }
            if key == "style/font_point",     let v = val as? Int    { style.fontPoint = v }
        }
    }

    private func loadBehaviorConfig() {
        let path = rimeDir.appendingPathComponent("default.custom.yaml")
        guard let content = try? String(contentsOf: path, encoding: .utf8),
              let yaml = try? Yams.load(yaml: content) as? [String: Any],
              let patch = yaml["patch"] as? [String: Any] else { return }

        if let menu = patch["menu"] as? [String: Any],
           let ps = menu["page_size"] as? Int { behavior.pageSize = ps }
        // Also check flat key "menu/page_size"
        if let ps = patch["menu/page_size"] as? Int { behavior.pageSize = ps }
    }

    // MARK: - Save
    // 保存后供 UI 展示的文件内容摘要
    @Published var lastSavedSquirrelYAML: String = ""
    @Published var lastSavedDefaultYAML:  String = ""

    func saveConfig() throws {
        try createRimeDirIfNeeded()
        try saveSquirrelCustom()
        try saveDefaultCustom()
    }

    private func createRimeDirIfNeeded() throws {
        if !FileManager.default.fileExists(atPath: rimeDir.path) {
            try FileManager.default.createDirectory(at: rimeDir,
                withIntermediateDirectories: true)
        }
    }

    /// 手写 YAML 模板，避免 Yams.dump 对整数/布尔值产生引号或格式异常
    private func saveSquirrelCustom() throws {
        func b(_ v: Bool) -> String { v ? "true" : "false" }
        // 字体名含空格时用引号
        func q(_ s: String) -> String {
            s.contains(" ") ? "\"\(s)\"" : s
        }
        let yaml = """
# Generated by RimeConfigurator — do not edit manually
patch:
  style/color_scheme: \(style.colorScheme)
  style/font_face: \(q(style.fontFace))
  style/font_point: \(style.fontPoint)
  style/label_font_face: \(q(style.labelFontFace))
  style/label_font_point: \(style.labelFontPoint)
  style/candidate_list_layout: \(style.candidateListLayout)
  style/text_orientation: \(style.textOrientation)
  style/inline_preedit: \(b(style.inlinePreedit))
  style/inline_candidate: \(b(style.inlineCandidate))
  style/translucency: \(b(style.translucency))
  style/corner_radius: \(style.cornerRadius)
  style/hilited_corner_radius: \(style.hiliteCornerRadius)
  style/border_height: \(style.borderHeight)
  style/border_width: \(style.borderWidth)
  style/line_spacing: \(style.lineSpacing)
  style/spacing: \(style.spacing)
  style/shadow_size: \(style.shadowSize)
  style/show_paging: \(b(style.showPaging))
"""
        lastSavedSquirrelYAML = yaml
        let path = rimeDir.appendingPathComponent("squirrel.custom.yaml")
        try yaml.write(to: path, atomically: true, encoding: .utf8)
    }

    private func saveDefaultCustom() throws {
        // schema_list 块
        var schemaBlock = ""
        for item in enabledSchemas {
            schemaBlock += "    - schema: \(item.id)\n"
            schemaBlock += "      name: \"\(item.name)\"\n"
        }
        let yaml = """
# Generated by RimeConfigurator — do not edit manually
patch:
  menu/page_size: \(behavior.pageSize)
  schema_list:
\(schemaBlock)
"""
        lastSavedDefaultYAML = yaml
        let path = rimeDir.appendingPathComponent("default.custom.yaml")
        try yaml.write(to: path, atomically: true, encoding: .utf8)
    }

    // MARK: - Deploy

    /// 返回 true 表示成功通知 Squirrel，false 表示需要手动点击菜单栏
    @discardableResult
    func deployRime() -> Bool {
        // 首选：通过 NSDistributedNotificationCenter 直接通知 Squirrel 进程重新部署
        // 这是 Squirrel 在菜单栏「重新部署」时使用的同一机制
        let center = DistributedNotificationCenter.default()
        // Swift 的 DistributedNotificationCenter 不暴露 deliverImmediately 参数，直接 post
        center.post(name: Notification.Name("RimeSchemaSelectorUpdate"), object: "deploy")
        center.post(name: Notification.Name("RimeDeployAction"), object: nil)

        // 备用：touch installation.yaml（Squirrel 激活时会检测时间戳变化）
        let installPath = rimeDir.appendingPathComponent("installation.yaml")
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: installPath.path
        )

        // 备用：尝试通过命令行触发
        let squirrelBin = "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel"
        if FileManager.default.fileExists(atPath: squirrelBin) {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: squirrelBin)
            p.arguments = ["--reload"]
            p.standardOutput = FileHandle.nullDevice
            p.standardError  = FileHandle.nullDevice
            try? p.run()
        }

        return true
    }

    // MARK: - Schema Mutations

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

    var disabledSchemas: [SchemaItem] {
        availableSchemas.filter { s in !enabledSchemas.contains(where: { $0.id == s.id }) }
    }

    var currentColorScheme: RimeColorScheme? {
        colorSchemes.first { $0.id == style.colorScheme }
    }

    // MARK: - Fallback Schemes

    static let fallbackSchemes: [RimeColorScheme] = [
        RimeColorScheme(
            id: "native", name: "系统原生／Native", author: "Squirrel",
            backColor:                  RimeColor(rawValue: 0xFFFFFF),
            borderColor:                RimeColor(rawValue: 0xCCCCCC),
            textColor:                  RimeColor(rawValue: 0x000000),
            candidateTextColor:         RimeColor(rawValue: 0x000000),
            commentTextColor:           RimeColor(rawValue: 0x999999),
            labelColor:                 RimeColor(rawValue: 0x888888),
            hilitedCandidateBackColor:  RimeColor(rawValue: 0xCCE8FF),
            hilitedCandidateTextColor:  RimeColor(rawValue: 0x000000),
            hilitedCommentTextColor:    RimeColor(rawValue: 0x777777),
            hilitedTextColor:           RimeColor(rawValue: 0x000000)
        ),
        RimeColorScheme(
            id: "luna", name: "明月／Luna", author: "佛振",
            backColor:                  RimeColor(rawValue: 0xF3F3EC),
            borderColor:                RimeColor(rawValue: 0xE0E0D5),
            textColor:                  RimeColor(rawValue: 0x5A4A2F),
            candidateTextColor:         RimeColor(rawValue: 0x5A4A2F),
            commentTextColor:           RimeColor(rawValue: 0x999999),
            labelColor:                 RimeColor(rawValue: 0xBBAA88),
            hilitedCandidateBackColor:  RimeColor(rawValue: 0xCDA76E),
            hilitedCandidateTextColor:  RimeColor(rawValue: 0xFFFFFF),
            hilitedCommentTextColor:    RimeColor(rawValue: 0xF0DFC8),
            hilitedTextColor:           RimeColor(rawValue: 0x5A4A2F)
        )
    ]
}
