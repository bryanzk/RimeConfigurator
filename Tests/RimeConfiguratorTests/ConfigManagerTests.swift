import Foundation
import Testing
@testable import RimeConfigurator

@MainActor
@Suite("ConfigManager")
struct ConfigManagerTests {
    @Test("保存配置会写入 app_options 并更新脏状态")
    func saveConfigWritesAppOptionsAndTracksDirtyState() async throws {
        let workspace = try makeWorkspace()
        let manager = ConfigManager(
            rimeDir: workspace.rimeDir,
            sharedSupportDir: workspace.sharedSupportDir,
            deployPerformer: .noop
        )

        manager.loadConfig()
        #expect(manager.hasUnsavedChanges == false)

        manager.style.showPaging = true
        manager.appOptions = [
            AppOption(bundleID: "com.apple.Terminal", asciiMode: true, inlineMode: false, noInline: true, vimMode: false)
        ]

        #expect(manager.hasUnsavedChanges == true)

        try manager.saveConfig()

        let squirrelText = try String(contentsOf: workspace.rimeDir.appendingPathComponent("squirrel.custom.yaml"))
        #expect(squirrelText.contains("app_options/com.apple.Terminal/ascii_mode: true"))
        #expect(squirrelText.contains("app_options/com.apple.Terminal/no_inline: true"))
        #expect(squirrelText.contains("style/show_paging: true"))
        #expect(manager.hasUnsavedChanges == false)
    }

    @Test("读取配置会解析 app_options")
    func loadConfigReadsAppOptionsFromCustomFile() async throws {
        let workspace = try makeWorkspace()
        let squirrelCustom = """
        patch:
          app_options/com.apple.Terminal/ascii_mode: true
          app_options/com.apple.Terminal/no_inline: true
          app_options/com.microsoft.VSCode/ascii_mode: true
          app_options/com.microsoft.VSCode/vim_mode: false
        """
        try squirrelCustom.write(
            to: workspace.rimeDir.appendingPathComponent("squirrel.custom.yaml"),
            atomically: true,
            encoding: .utf8
        )

        let manager = ConfigManager(
            rimeDir: workspace.rimeDir,
            sharedSupportDir: workspace.sharedSupportDir,
            deployPerformer: .noop
        )
        manager.loadConfig()

        #expect(manager.appOptions.count == 2)
        #expect(manager.appOptions.first?.bundleID == "com.apple.Terminal")
        #expect(manager.appOptions.first?.asciiMode == true)
        #expect(manager.appOptions.first?.noInline == true)
    }

    @Test("部署结果可根据 build 时间戳推断自动成功")
    func deployResultInfersAutomaticSuccessFromBuildTimestamp() {
        let before = Date(timeIntervalSince1970: 100)
        let after = Date(timeIntervalSince1970: 120)

        let result = DeployFeedback.infer(
            strings: AppStrings(language: .simplifiedChineseChina),
            beforeBuildDate: before,
            afterBuildDate: after,
            reloadAttempted: true,
            binaryAvailable: true
        )

        #expect(result.state == .deployedAutomatically)
    }

    @Test("诊断会报告缺失的 SharedSupport 和用户目录")
    func diagnosticsReportMissingSharedSupportAndUserDirectory() async throws {
        let workspace = try makeWorkspace(createRimeDir: false, createSharedSupportDir: false)
        let manager = ConfigManager(
            rimeDir: workspace.rimeDir,
            sharedSupportDir: workspace.sharedSupportDir,
            deployPerformer: .noop
        )

        manager.loadConfig()

        #expect(manager.diagnostics.contains(where: { $0.kind == .error }))
        #expect(manager.diagnostics.contains(where: { $0.message.contains("SharedSupport") }))
        #expect(manager.diagnostics.contains(where: { $0.message.contains("Library/Rime") }))
    }

    @Test("放弃修改会恢复已加载快照")
    func discardChangesRestoresLoadedSnapshot() async throws {
        let workspace = try makeWorkspace()
        let manager = ConfigManager(
            rimeDir: workspace.rimeDir,
            sharedSupportDir: workspace.sharedSupportDir,
            deployPerformer: .noop
        )

        manager.loadConfig()
        manager.behavior.pageSize = 5
        manager.style.fontPoint = 22

        #expect(manager.hasUnsavedChanges == true)

        manager.discardChanges()

        #expect(manager.hasUnsavedChanges == false)
        #expect(manager.behavior.pageSize == 9)
        #expect(manager.style.fontPoint == 16)
    }

    @Test("使用语言会从偏好设置加载并持久化")
    func languagePreferenceLoadsAndPersists() async throws {
        let workspace = try makeWorkspace()
        let defaults = UserDefaults(suiteName: "RimeConfiguratorTests.\(UUID().uuidString)")!
        defaults.set(AppLanguage.english.rawValue, forKey: ConfigManager.languageDefaultsKey)

        let manager = ConfigManager(
            rimeDir: workspace.rimeDir,
            sharedSupportDir: workspace.sharedSupportDir,
            userDefaults: defaults,
            deployPerformer: .noop
        )

        manager.loadConfig()
        #expect(manager.language == .english)
        #expect(manager.strings.saveAndDeploy == "Save & Deploy")

        manager.setLanguage(.traditionalChineseTaiwan)

        #expect(defaults.string(forKey: ConfigManager.languageDefaultsKey) == AppLanguage.traditionalChineseTaiwan.rawValue)
        #expect(manager.strings.saveAndDeploy == "儲存並重新部署")
    }

    @Test("四种语言选项顺序固定")
    func languageOptionsOrderIsStable() {
        #expect(AppLanguage.allCases == [.english, .simplifiedChineseChina, .traditionalChineseTaiwan, .traditionalChineseHongKong])
    }

    @Test("本机 App 包可解析显示名与 Bundle ID")
    func appBundleDescriptorParsesLocalApp() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appURL = root.appendingPathComponent("Demo.app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)

        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.example.Demo</string>
            <key>CFBundleDisplayName</key>
            <string>Demo App</string>
            <key>CFBundleName</key>
            <string>Demo</string>
        </dict>
        </plist>
        """
        try plist.write(to: contentsURL.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)

        let descriptor = try #require(AppBundleDescriptor(appURL: appURL))
        #expect(descriptor.bundleID == "com.example.Demo")
        #expect(descriptor.displayName == "Demo App")
    }

    private func makeWorkspace(
        createRimeDir: Bool = true,
        createSharedSupportDir: Bool = true
    ) throws -> TestWorkspace {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let rimeDir = root.appendingPathComponent("Library/Rime", isDirectory: true)
        let sharedSupportDir = root.appendingPathComponent("SharedSupport", isDirectory: true)
        let buildDir = rimeDir.appendingPathComponent("build", isDirectory: true)

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        if createRimeDir {
            try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
            try """
            config_version: "1.0"
            preset_color_schemes:
              native:
                name: "Native"
                back_color: 0xFFFFFF
            """.write(
                to: buildDir.appendingPathComponent("squirrel.yaml"),
                atomically: true,
                encoding: .utf8
            )
            try """
            patch:
              menu/page_size: 9
              schema_list:
                - schema: luna_pinyin
                  name: "朙月拼音"
            """.write(
                to: rimeDir.appendingPathComponent("default.custom.yaml"),
                atomically: true,
                encoding: .utf8
            )
        }
        if createSharedSupportDir {
            try FileManager.default.createDirectory(at: sharedSupportDir, withIntermediateDirectories: true)
            try """
            schema:
              schema_id: luna_pinyin
              name: "朙月拼音"
            """.write(
                to: sharedSupportDir.appendingPathComponent("luna_pinyin.schema.yaml"),
                atomically: true,
                encoding: .utf8
            )
        }

        return TestWorkspace(rimeDir: rimeDir, sharedSupportDir: sharedSupportDir)
    }
}

private struct TestWorkspace {
    let rimeDir: URL
    let sharedSupportDir: URL
}
