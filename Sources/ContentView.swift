import SwiftUI

enum NavTab: CaseIterable, Identifiable {
    case schemas
    case appearance
    case behavior

    var id: String { systemImage }

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
    @State private var showDiscardAlert = false

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
        .alert(config.strings.saveFailed, isPresented: $showDeployAlert) {
            Button(config.strings.ok) { deployResult = nil }
        } message: {
            if case .failure(let msg) = deployResult { Text(msg) }
        }
        .alert(config.strings.discardUnsavedTitle, isPresented: $showDiscardAlert) {
            Button(config.strings.continueEditing, role: .cancel) { }
            Button(config.strings.discardChanges, role: .destructive) {
                config.discardChanges()
            }
        } message: {
            Text(config.strings.discardUnsavedMessage)
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
                Text(config.strings.appName)
                    .font(.headline)
                Text(config.strings.appSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Nav items
            List(NavTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(config.strings.tabTitle(tab), systemImage: tab.systemImage)
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Rime version info
            VStack(spacing: 2) {
                Text(config.strings.squirrelLabel)
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
        VStack(spacing: 0) {
            if let diagnostic = config.primaryDiagnostic {
                diagnosticBanner(diagnostic)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }

            if config.isLoaded {
                switch selectedTab {
                case .schemas:    SchemasView()
                case .appearance: AppearanceView()
                case .behavior:   BehaviorView()
                }
            } else {
                ProgressView(config.strings.readingConfig)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            if config.hasUnsavedChanges {
                Label(config.strings.unsavedChanges, systemImage: "circle.fill")
                    .foregroundStyle(.orange)
                    .help(config.strings.unsavedChangesHelp)
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button(action: saveAndDeploy) {
                if isDeploying {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text(config.strings.deploying)
                    }
                } else {
                    Label(config.strings.saveAndDeploy, systemImage: "arrow.clockwise.circle.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isDeploying || !config.isLoaded)
            .help(config.strings.saveAndDeployHelp)
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }

        ToolbarItem {
            Button(action: reloadFromDisk) {
                Label(config.strings.reload, systemImage: "arrow.counterclockwise")
            }
            .help(config.strings.reloadHelp)
            .disabled(isDeploying || !config.isLoaded)
        }
    }

    // MARK: - Actions

    private func saveAndDeploy() {
        isDeploying = true
        Task {
            do {
                _ = try await config.saveAndDeploy()
                await MainActor.run {
                    isDeploying     = false
                    showSavedSheet  = true
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

    private func reloadFromDisk() {
        if config.hasUnsavedChanges {
            showDiscardAlert = true
        } else {
            config.loadConfig()
        }
    }

    @ViewBuilder
    private func diagnosticBanner(_ diagnostic: ConfigDiagnostic) -> some View {
        let style = diagnosticStyle(for: diagnostic.kind)

        HStack(alignment: .top, spacing: 12) {
            Image(systemName: style.icon)
                .foregroundStyle(style.color)
            VStack(alignment: .leading, spacing: 4) {
                Text(diagnostic.message)
                    .font(.callout)
                if config.diagnostics.count > 1 {
                    Text(config.strings.moreDiagnostics(config.diagnostics.count - 1))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(style.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func diagnosticStyle(for kind: ConfigDiagnosticKind) -> (color: Color, icon: String) {
        switch kind {
        case .error:
            return (.red, "exclamationmark.octagon.fill")
        case .warning:
            return (.orange, "exclamationmark.triangle.fill")
        case .info:
            return (.blue, "info.circle.fill")
        }
    }
}
