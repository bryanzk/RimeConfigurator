import SwiftUI

enum NavTab: String, CaseIterable, Identifiable {
    case schemas    = "输入方案"
    case appearance = "外观设置"
    case behavior   = "行为设置"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .schemas:    return "keyboard"
        case .appearance: return "paintbrush"
        case .behavior:   return "gearshape"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var config: ConfigManager
    @State private var selectedTab: NavTab = .schemas
    @State private var isDeploying      = false
    @State private var deployResult:    DeployResult?
    @State private var showDeployAlert  = false
    @State private var showSavedSheet   = false

    enum DeployResult {
        case success
        case failure(String)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .toolbar { toolbarContent }
        .alert("保存失败", isPresented: $showDeployAlert) {
            Button("好") { deployResult = nil }
        } message: {
            if case .failure(let msg) = deployResult { Text(msg) }
        }
        .sheet(isPresented: $showSavedSheet) {
            SavedResultSheet(isPresented: $showSavedSheet)
                .environmentObject(config)
        }
        .onAppear { config.loadConfig() }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // App header
            VStack(spacing: 4) {
                Image(systemName: "keyboard.badge.ellipsis")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 36))
                Text("鼠须管配置器")
                    .font(.headline)
                Text("RIME Squirrel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Nav items
            List(NavTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.systemImage)
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Rime version info
            VStack(spacing: 2) {
                Text("Squirrel 鼠须管")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("RIME \(rimeVersion)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
        }
        .frame(minWidth: 180, idealWidth: 200)
    }

    private var rimeVersion: String {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Rime/installation.yaml")
        if let content = try? String(contentsOf: path, encoding: .utf8) {
            for line in content.split(separator: "\n") {
                let s = String(line)
                if s.hasPrefix("rime_version:") {
                    return s.dropFirst("rime_version:".count).trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return "1.x"
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if config.isLoaded {
            switch selectedTab {
            case .schemas:    SchemasView()
            case .appearance: AppearanceView()
            case .behavior:   BehaviorView()
            }
        } else {
            ProgressView("正在读取配置…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: saveAndDeploy) {
                if isDeploying {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text("部署中…")
                    }
                } else {
                    Label("保存并部署", systemImage: "arrow.clockwise.circle.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isDeploying || !config.isLoaded)
            .help("保存配置文件并重新部署 RIME（⌘⇧R）")
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }

        ToolbarItem {
            Button(action: { config.loadConfig() }) {
                Label("重新读取", systemImage: "arrow.counterclockwise")
            }
            .help("放弃修改，重新从磁盘读取配置")
            .disabled(isDeploying)
        }
    }

    // MARK: - Actions

    private func saveAndDeploy() {
        isDeploying = true
        Task {
            do {
                try config.saveConfig()
                config.deployRime()       // 非 throws，内部多策略尝试
                await MainActor.run {
                    isDeploying     = false
                    showSavedSheet  = true  // 展示已保存内容 + 手动部署提示
                }
            } catch {
                await MainActor.run {
                    deployResult    = .failure(error.localizedDescription)
                    showDeployAlert = true
                    isDeploying     = false
                }
            }
        }
    }
}
