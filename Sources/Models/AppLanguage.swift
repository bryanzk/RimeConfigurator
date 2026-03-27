import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Equatable {
    case english = "en"
    case simplifiedChineseChina = "zh-Hans-CN"
    case traditionalChineseTaiwan = "zh-Hant-TW"
    case traditionalChineseHongKong = "zh-Hant-HK"

    var id: String { rawValue }
}

struct AppStrings {
    let language: AppLanguage

    func languageName(_ option: AppLanguage) -> String {
        switch option {
        case .english:
            return value("English", "英文", "英文", "英文")
        case .simplifiedChineseChina:
            return value("Simplified Chinese", "简体中文", "簡體中文", "簡體中文")
        case .traditionalChineseTaiwan:
            return value("Traditional Chinese (Taiwan)", "繁体中文（台湾）", "繁體中文（台灣）", "繁體中文（台灣）")
        case .traditionalChineseHongKong:
            return value("Traditional Chinese (Hong Kong)", "繁体中文（香港）", "繁體中文（香港）", "繁體中文（香港）")
        }
    }

    func tabTitle(_ tab: NavTab) -> String {
        switch tab {
        case .schemas:
            return value("Input Schemas", "输入方案", "輸入方案", "輸入方案")
        case .appearance:
            return value("Appearance", "外观设置", "外觀設定", "外觀設定")
        case .behavior:
            return value("Behavior", "行为设置", "行為設定", "行為設定")
        }
    }

    var appName: String { value("RimeConfigurator", "鼠须管配置器", "鼠鬚管設定器", "鼠鬚管設定器") }
    var appSubtitle: String { value("RIME Squirrel", "RIME Squirrel", "RIME Squirrel", "RIME Squirrel") }
    var squirrelLabel: String { value("Squirrel", "Squirrel 鼠须管", "Squirrel 鼠鬚管", "Squirrel 鼠鬚管") }
    var saveAndDeploy: String { value("Save & Deploy", "保存并部署", "儲存並重新部署", "儲存並重新部署") }
    var saveAndDeployMenu: String { value("Save & Deploy RIME", "保存并部署 RIME", "儲存並重新部署 RIME", "儲存並重新部署 RIME") }
    var saveFailed: String { value("Save Failed", "保存失败", "儲存失敗", "儲存失敗") }
    var ok: String { value("OK", "好", "好", "好") }
    var discardUnsavedTitle: String { value("Discard unsaved changes?", "放弃未保存的更改？", "放棄未儲存的更改？", "放棄未儲存的更改？") }
    var continueEditing: String { value("Keep Editing", "继续编辑", "繼續編輯", "繼續編輯") }
    var discardChanges: String { value("Discard Changes", "放弃更改", "放棄更改", "放棄更改") }
    var discardUnsavedMessage: String { value("Reloading will discard all unsaved changes.", "重新读取会丢弃当前所有未保存的修改。", "重新載入會捨棄目前所有未儲存的修改。", "重新載入會捨棄目前所有未儲存的修改。") }
    var readingConfig: String { value("Reading configuration…", "正在读取配置…", "正在讀取設定…", "正在讀取設定…") }
    var unsavedChanges: String { value("Unsaved Changes", "未保存更改", "未儲存變更", "未儲存變更") }
    var unsavedChangesHelp: String { value("There are unsaved changes.", "当前有未保存的更改", "目前有未儲存的變更", "目前有未儲存的變更") }
    var deploying: String { value("Deploying…", "部署中…", "重新部署中…", "重新部署中…") }
    var saveAndDeployHelp: String { value("Save configuration and redeploy RIME (⌘⇧R)", "保存配置文件并重新部署 RIME（⌘⇧R）", "儲存設定並重新部署 RIME（⌘⇧R）", "儲存設定並重新部署 RIME（⌘⇧R）") }
    var reload: String { value("Reload", "重新读取", "重新載入", "重新載入") }
    var reloadHelp: String { value("Discard edits and reload from disk", "放弃修改，重新从磁盘读取配置", "捨棄修改並從磁碟重新載入", "捨棄修改並從磁碟重新載入") }
    func moreDiagnostics(_ count: Int) -> String {
        switch language {
        case .english:
            return "\(count) more environment hints are available on this page."
        case .simplifiedChineseChina:
            return "还有 \(count) 项提示，可在当前页面继续检查配置。"
        case .traditionalChineseTaiwan:
            return "還有 \(count) 項提示，可在目前頁面繼續檢查設定。"
        case .traditionalChineseHongKong:
            return "還有 \(count) 項提示，可在目前頁面繼續檢查設定。"
        }
    }

    var schemasEnabledTitle: String { value("Enabled Schemas", "已启用的输入方案", "已啟用的輸入方案", "已啟用的輸入方案") }
    var schemasEnabledEmptyTitle: String { value("No enabled schemas", "暂无已启用方案", "暫無已啟用方案", "暫無已啟用方案") }
    var schemasEnabledEmptySubtitle: String { value("Add input schemas from the right.", "从右侧添加输入方案", "從右側新增輸入方案", "從右側新增輸入方案") }
    var schemasReorderHint: String { value("Drag to reorder. The first schema becomes the default.", "拖动行可调整切换顺序，排在首位的方案将作为默认方案", "拖曳可調整切換順序，排在第一位的方案會成為預設方案", "拖曳可調整切換順序，排在第一位的方案會成為預設方案") }
    var schemasAvailableTitle: String { value("Available Library", "可用方案库", "可用方案庫", "可用方案庫") }
    var schemasSearchPlaceholder: String { value("Search schemas…", "搜索方案…", "搜尋方案…", "搜尋方案…") }
    func noSchemasFound(sharedSupportPath: String) -> String {
        switch language {
        case .english:
            return "Make sure Squirrel is installed and check \(sharedSupportPath) and ~/Library/Rime."
        case .simplifiedChineseChina:
            return "请确认 Squirrel 已正确安装\n并检查 \(sharedSupportPath) 与 ~/Library/Rime"
        case .traditionalChineseTaiwan:
            return "請確認 Squirrel 已正確安裝\n並檢查 \(sharedSupportPath) 與 ~/Library/Rime"
        case .traditionalChineseHongKong:
            return "請確認 Squirrel 已正確安裝\n並檢查 \(sharedSupportPath) 與 ~/Library/Rime"
        }
    }
    var schemasNoAvailableTitle: String { value("No schemas found", "未找到可用方案", "未找到可用方案", "未找到可用方案") }
    var schemasNoMatchTitle: String { value("No matches", "无匹配结果", "沒有相符結果", "沒有相符結果") }
    var schemasNoMatchSubtitle: String { value("Try another keyword.", "尝试其他关键字", "試試其他關鍵字", "試試其他關鍵字") }
    var schemasAllEnabled: String { value("All schemas are enabled", "所有方案均已启用", "所有方案均已啟用", "所有方案均已啟用") }
    var schemasAddHint: String { value("Click + to add a schema to the enabled list.", "点击 + 将方案添加到已启用列表", "點擊 + 將方案加入已啟用清單", "點擊 + 將方案加入已啟用清單") }

    var close: String { value("Close", "关闭", "關閉", "關閉") }
    var openConfigInFinder: String { value("Reveal Config Files in Finder", "在访达中查看配置文件", "在 Finder 中查看設定檔", "在 Finder 中查看設定檔") }
    var manualStep1: String { value("Find the Squirrel menu-bar icon.", "查看菜单栏右侧，找到「鼠」字图标（鼠须管）", "查看選單列右側，找到「鼠」字圖示（鼠鬚管）", "查看選單列右側，找到「鼠」字圖示（鼠鬚管）") }
    var manualStep2: String { value("Choose “Redeploy” from the menu.", "点击该图标，在下拉菜单中选择「重新部署」", "點擊該圖示，在下拉選單中選擇「重新部署」", "點擊該圖示，在下拉選單中選擇「重新部署」") }
    var manualStep3: String { value("Wait 2–3 seconds and verify the new settings.", "等待 2–3 秒，再确认设置是否生效", "等待 2–3 秒，再確認設定是否生效", "等待 2–3 秒，再確認設定是否生效") }

    var appearanceTitle: String { value("Appearance", "外观设置", "外觀設定", "外觀設定") }
    var appearanceDescription: String { value("Preview tries to match the real candidate window. Blur intensity and some inline behavior still depend on real deployment.", "预览会尽量模拟真实候选窗，但磨砂强度与特定 App 内嵌行为仍以实际部署效果为准。", "預覽會盡量模擬真實候選窗，但磨砂強度與特定 App 內嵌行為仍以實際部署效果為準。", "預覽會盡量模擬真實候選窗，但磨砂強度與特定 App 內嵌行為仍以實際部署效果為準。") }
    var resetAppearanceDefaults: String { value("Reset Appearance Defaults", "恢复外观默认值", "恢復外觀預設值", "恢復外觀預設值") }
    var previewTitle: String { value("Candidate Preview", "候选窗口预览", "候選視窗預覽", "候選視窗預覽") }
    var previewCoverage: String { value("Covered: layout, text direction, border padding, paging arrows, and approximate translucency.", "已覆盖：排布、文字方向、边框留白、翻页箭头、透明背景近似效果。", "已涵蓋：排版、文字方向、邊框留白、翻頁箭頭與透明背景近似效果。", "已涵蓋：排版、文字方向、邊框留白、翻頁箭頭與透明背景近似效果。") }
    var colorSchemes: String { value("Color Schemes", "颜色方案", "顏色方案", "顏色方案") }
    var fontSettings: String { value("Fonts", "字体设置", "字體設定", "字體設定") }
    var candidateFont: String { value("Candidate Font", "候选词字体", "候選字型", "候選字型") }
    var labelFont: String { value("Label Font", "标签字体", "標籤字型", "標籤字型") }
    var layoutTitle: String { value("Layout", "排列方式", "排列方式", "排列方式") }
    var candidateLayout: String { value("Candidate Layout", "候选词布局", "候選排列", "候選排列") }
    var vertical: String { value("Vertical", "竖排", "直排", "直排") }
    var horizontal: String { value("Horizontal", "横排", "橫排", "橫排") }
    var textDirection: String { value("Text Direction", "文字方向", "文字方向", "文字方向") }
    var inlinePreedit: String { value("Inline Preedit", "在线预编辑", "行內預編輯", "行內預編輯") }
    var inlineCandidate: String { value("Inline Candidate", "候选内嵌", "候選內嵌", "候選內嵌") }
    var translucency: String { value("Translucency", "磨砂透明", "毛玻璃透明", "毛玻璃透明") }
    var showPaging: String { value("Show Paging", "显示翻页", "顯示翻頁", "顯示翻頁") }
    var geometryTitle: String { value("Geometry", "尺寸与间距", "尺寸與間距", "尺寸與間距") }
    var cornerRadius: String { value("Corner Radius", "圆角半径", "圓角半徑", "圓角半徑") }
    var hiliteCornerRadius: String { value("Highlight Radius", "高亮圆角", "高亮圓角", "高亮圓角") }
    var borderHeight: String { value("Border Height", "边框高度", "邊框高度", "邊框高度") }
    var borderWidth: String { value("Border Width", "边框宽度", "邊框寬度", "邊框寬度") }
    var lineSpacing: String { value("Line Spacing", "行间距", "行距", "行距") }
    var spacing: String { value("Candidate Spacing", "候选间距", "候選間距", "候選間距") }
    var shadowSize: String { value("Shadow Size", "阴影大小", "陰影大小", "陰影大小") }

    var behaviorTitle: String { value("Behavior", "行为设置", "行為設定", "行為設定") }
    var behaviorDescription: String { value("These settings affect candidate count, input mode, and per-app defaults.", "这里的修改会直接影响候选数量、输入模式和特定 App 下的默认行为。", "這裡的修改會直接影響候選數量、輸入模式與特定 App 的預設行為。", "這裡的修改會直接影響候選數量、輸入模式與特定 App 的預設行為。") }
    var resetBehaviorDefaults: String { value("Reset Behavior Defaults", "恢复本页默认值", "恢復本頁預設值", "恢復本頁預設值") }
    var languageTitle: String { value("Interface Language", "使用语言", "使用語言", "使用語言") }
    var languageDescription: String { value("Choose the language used by this app interface.", "选择此应用界面使用的语言。", "選擇此 App 介面使用的語言。", "選擇此 App 介面使用的語言。") }
    var pageSizeTitle: String { value("Candidates Per Page", "每页候选词数量", "每頁候選數量", "每頁候選數量") }
    func currentPageSize(_ value: Int) -> String {
        switch language {
        case .english:
            return "Current setting: \(value) candidates per page"
        case .simplifiedChineseChina:
            return "当前设置：每页显示 \(value) 个候选词"
        case .traditionalChineseTaiwan:
            return "目前設定：每頁顯示 \(value) 個候選字"
        case .traditionalChineseHongKong:
            return "目前設定：每頁顯示 \(value) 個候選字"
        }
    }
    var inputBehaviorTitle: String { value("Input Behavior", "输入行为", "輸入行為", "輸入行為") }
    var inlinePreeditDescription: String { value("Show the composing text at the cursor without a separate preedit panel.", "在光标处直接显示正在输入的拼音，不弹出单独的预编辑框", "在游標位置直接顯示正在輸入的拼音，不跳出獨立的預編輯框", "在游標位置直接顯示正在輸入的拼音，不跳出獨立的預編輯框") }
    var inlineCandidateDescription: String { value("Embed candidates at the cursor position instead of showing the candidate window.", "候选词直接内嵌在光标位置，不显示候选窗口", "候選字直接內嵌在游標位置，不顯示候選視窗", "候選字直接內嵌在游標位置，不顯示候選視窗") }
    var translucencyDescription: String { value("Use a translucent blurred background for the candidate window when supported.", "候选窗口背景使用半透明磨砂效果（需要系统支持）", "候選視窗背景使用半透明毛玻璃效果（需系統支援）", "候選視窗背景使用半透明毛玻璃效果（需系統支援）") }
    var showPagingDescription: String { value("Show previous/next paging arrows in the candidate window.", "在候选窗口中显示上一页/下一页的箭头按钮", "在候選視窗中顯示上一頁／下一頁箭頭按鈕", "在候選視窗中顯示上一頁／下一頁箭頭按鈕") }
    var appOverrideTitle: String { value("Per-App Overrides", "按应用覆盖配置", "按 App 覆寫設定", "按 App 覆寫設定") }
    var appOverrideDescription: String { value("Override defaults for specific apps. Common use: start in English mode inside terminals or editors.", "为特定应用单独设置默认行为。最常见的用法是在终端、编辑器中默认进入英文模式。", "為特定 App 單獨設定預設行為。最常見的用法是在終端機、編輯器中預設進入英文模式。", "為特定 App 單獨設定預設行為。最常見的用法是在終端機、編輯器中預設進入英文模式。") }
    var bundleIDPlaceholder: String { value("Bundle ID, e.g. com.apple.Terminal", "Bundle ID，例如 com.apple.Terminal", "Bundle ID，例如 com.apple.Terminal", "Bundle ID，例如 com.apple.Terminal") }
    var add: String { value("Add", "添加", "加入", "加入") }
    var chooseApp: String { value("Choose App…", "选择 App…", "選擇 App…", "選擇 App…") }
    var chooseAppErrorTitle: String { value("Unable to read app info", "无法读取 App 信息", "無法讀取 App 資訊", "無法讀取 App 資訊") }
    var chooseAppErrorMessage: String { value("The selected app does not expose a valid bundle identifier.", "所选 App 没有可用的 Bundle ID。", "所選 App 沒有可用的 Bundle ID。", "所選 App 沒有可用的 Bundle ID。") }
    var noAppOverrides: String { value("No app overrides yet. Add a Bundle ID directly or use one of the common app shortcuts above.", "还没有按应用覆盖。可直接添加 Bundle ID，或使用上面的常见 App 快捷入口。", "目前還沒有 App 覆寫。可直接加入 Bundle ID，或使用上方常見 App 捷徑。", "目前還沒有 App 覆寫。可直接加入 Bundle ID，或使用上方常見 App 捷徑。") }
    var appOverrideHint: String { value("Disabled switches are still written back so the GUI can round-trip them reliably.", "提示：未启用的开关也会写入配置，便于你在界面里稳定往返编辑。", "提示：未啟用的開關也會寫回設定，方便你在圖形介面中穩定往返編輯。", "提示：未啟用的開關也會寫回設定，方便你在圖形介面中穩定往返編輯。") }
    var appOnlyHere: String { value("Only applies to this app", "仅在该应用生效", "僅在此 App 生效", "僅在此 App 生效") }
    var appBundleIDLabel: String { value("Bundle ID", "Bundle ID", "Bundle ID", "Bundle ID") }
    var remove: String { value("Remove", "移除", "移除", "移除") }
    var defaultEnglish: String { value("Default English", "默认英文", "預設英文", "預設英文") }
    var embeddedCandidates: String { value("Inline Candidate", "内嵌候选", "內嵌候選", "內嵌候選") }
    var disableInline: String { value("Disable Inline", "禁用内嵌", "停用內嵌", "停用內嵌") }
    var vimMode: String { value("Vim Mode", "Vim 模式", "Vim 模式", "Vim 模式") }

    var previewInlineTitle: String { value("Inline candidate preview", "光标处内嵌候选预览", "游標處內嵌候選預覽", "游標處內嵌候選預覽") }
    var previewPreeditText: String { value("ni hao", "ni hao", "ni hao", "ni hao") }
    var previewCandidates: [String] {
        switch language {
        case .english:
            return ["hello", "hullo", "greeting", "hi there", "hello!"]
        case .simplifiedChineseChina:
            return ["你好", "拟好", "泥濠", "倪浩", "逆号"]
        case .traditionalChineseTaiwan:
            return ["你好", "擬好", "泥濠", "倪浩", "逆號"]
        case .traditionalChineseHongKong:
            return ["你好", "擬好", "泥濠", "倪浩", "逆號"]
        }
    }
    var candidateSample: String { value("Candidate", "候选", "候選", "候選") }
    var highlightSample: String { value("Selected", "高亮", "高亮", "高亮") }
    var pagingIndicator: String { value("1 / 3", "1 / 3", "1 / 3", "1 / 3") }

    var diagnosticsLoaded: String { value("Configuration loaded", "配置已读取", "設定已讀取", "設定已讀取") }
    func diagnosticsCount(_ count: Int) -> String {
        switch language {
        case .english:
            return "\(count) environment hints detected"
        case .simplifiedChineseChina:
            return "检测到 \(count) 项环境提示"
        case .traditionalChineseTaiwan:
            return "偵測到 \(count) 項環境提示"
        case .traditionalChineseHongKong:
            return "偵測到 \(count) 項環境提示"
        }
    }
    var configurationSaved: String { value("Configuration saved", "配置已保存", "設定已儲存", "設定已儲存") }
    func missingSharedSupport(_ path: String) -> String {
        value("SharedSupport directory not found at \(path). Make sure Squirrel is installed.", "未找到鼠须管 SharedSupport 目录：\(path)。请先确认 Squirrel 已安装。", "找不到鼠鬚管 SharedSupport 目錄：\(path)。請先確認 Squirrel 已安裝。", "找不到鼠鬚管 SharedSupport 目錄：\(path)。請先確認 Squirrel 已安裝。")
    }
    func missingRimeDir(_ path: String) -> String {
        value("User config directory not found at \(path). It will be created on first save.", "尚未检测到用户配置目录：\(path)。首次保存时会自动创建。", "尚未偵測到使用者設定目錄：\(path)。首次儲存時會自動建立。", "尚未偵測到使用者設定目錄：\(path)。首次儲存時會自動建立。")
    }
    func noAvailableSchemasDiagnostic(sharedSupportPath: String, rimePath: String) -> String {
        value("No available schemas were found. Check \(sharedSupportPath) and \(rimePath).", "当前没有读取到可用输入方案，请检查 \(sharedSupportPath) 与 \(rimePath) 下的 schema 文件。", "目前沒有讀取到可用輸入方案，請檢查 \(sharedSupportPath) 與 \(rimePath) 下的 schema 檔案。", "目前沒有讀取到可用輸入方案，請檢查 \(sharedSupportPath) 與 \(rimePath) 下的 schema 檔案。")
    }
    var noEnabledSchemasDiagnostic: String { value("No schema is enabled. Keep at least one schema before saving.", "当前没有启用任何输入方案，保存后需要至少保留一个方案才能正常切换。", "目前沒有啟用任何輸入方案，儲存前至少保留一個方案才能正常切換。", "目前沒有啟用任何輸入方案，儲存前至少保留一個方案才能正常切換。") }

    var deployAutoTitle: String { value("Configuration saved and redeployed automatically", "配置已保存并自动重新部署", "設定已儲存並自動重新部署", "設定已儲存並自動重新部署") }
    var deployAutoMessage: String { value("RIME build output was refreshed. The new settings should already be active.", "检测到 RIME 的 build 输出已刷新，新设置通常已经生效。", "偵測到 RIME 的 build 輸出已更新，新設定通常已經生效。", "偵測到 RIME 的 build 輸出已更新，新設定通常已經生效。") }
    var deployRequestedTitle: String { value("Configuration saved, automatic redeploy requested", "配置已保存，已请求自动重新部署", "設定已儲存，已要求自動重新部署", "設定已儲存，已要求自動重新部署") }
    var deployRequestedMessage: String { value("A redeploy request was sent to Squirrel. If nothing changes after 2–3 seconds, redeploy manually.", "已向鼠须管发送重新部署请求。如 2–3 秒后仍未生效，可按下方步骤手动重新部署。", "已向鼠鬚管送出重新部署要求。如 2–3 秒後仍未生效，可依下方步驟手動重新部署。", "已向鼠鬚管送出重新部署要求。如 2–3 秒後仍未生效，可依下方步驟手動重新部署。") }
    var deployManualTitle: String { value("Configuration saved, manual redeploy required", "配置已保存，但需要手动重新部署", "設定已儲存，但需要手動重新部署", "設定已儲存，但需要手動重新部署") }
    var deployManualMessage: String { value("This environment could not confirm automatic redeploy. Please redeploy manually.", "当前环境无法确认自动重新部署是否可用，请按下方步骤手动重新部署。", "目前環境無法確認自動重新部署是否可用，請依下方步驟手動重新部署。", "目前環境無法確認自動重新部署是否可用，請依下方步驟手動重新部署。") }
    var deployTestTitle: String { value("Configuration saved", "配置已保存", "設定已儲存", "設定已儲存") }
    var deployTestMessage: String { value("Automatic redeploy was skipped in the test environment.", "测试环境未执行自动部署。", "測試環境未執行自動重新部署。", "測試環境未執行自動重新部署。") }

    private func value(_ english: String, _ zhHans: String, _ zhHantTW: String, _ zhHantHK: String) -> String {
        switch language {
        case .english:
            return english
        case .simplifiedChineseChina:
            return zhHans
        case .traditionalChineseTaiwan:
            return zhHantTW
        case .traditionalChineseHongKong:
            return zhHantHK
        }
    }
}
