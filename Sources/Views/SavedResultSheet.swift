import SwiftUI

/// 保存成功后弹出的 Sheet：展示写入的 YAML 内容与部署反馈
struct SavedResultSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var config: ConfigManager
    @State private var tab: SheetTab = .squirrel

    enum SheetTab: String, CaseIterable {
        case squirrel = "squirrel.custom.yaml"
        case defaults = "default.custom.yaml"
    }

    private var feedback: DeployFeedback {
        config.lastDeployFeedback ?? .noop(strings: config.strings)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: feedbackIcon)
                    .foregroundColor(feedbackColor)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(feedback.title).font(.headline)
                    Text("~/Library/Rime/").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button(config.strings.close) { isPresented = false }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)

            Divider()

            // Deploy feedback banner
            deployBanner

            Divider()

            // YAML preview tabs
            Picker("", selection: $tab) {
                ForEach(SheetTab.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)

            ScrollView {
                Text(tab == .squirrel
                     ? config.lastSavedSquirrelYAML
                     : config.lastSavedDefaultYAML)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.2)))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 600, height: 480)
    }

    // MARK: - Deploy Banner

    private var deployBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: feedbackIcon)
                .foregroundColor(feedbackColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 6) {
                Text(feedback.title)
                    .font(.headline)

                Text(feedback.message)
                    .font(.callout)
                    .foregroundColor(.secondary)

                if feedback.showsManualSteps {
                    VStack(alignment: .leading, spacing: 4) {
                        stepRow(n: "1", text: config.strings.manualStep1)
                        stepRow(n: "2", text: config.strings.manualStep2)
                        stepRow(n: "3", text: config.strings.manualStep3)
                    }
                    .padding(.top, 2)
                }

                Button(action: openRimeDirectory) {
                    Label(config.strings.openConfigInFinder, systemImage: "folder")
                }
                .buttonStyle(.link)
                .font(.callout)
            }
        }
        .padding(16)
        .background(feedbackColor.opacity(0.08))
    }

    private var feedbackColor: Color {
        switch feedback.state {
        case .deployedAutomatically:
            return .green
        case .deploymentRequested:
            return .blue
        case .manualActionRequired:
            return .orange
        }
    }

    private var feedbackIcon: String {
        switch feedback.state {
        case .deployedAutomatically:
            return "checkmark.circle.fill"
        case .deploymentRequested:
            return "arrow.trianglehead.clockwise.circle.fill"
        case .manualActionRequired:
            return "exclamationmark.triangle.fill"
        }
    }

    private func stepRow(n: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(n)
                .font(.caption2.bold())
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.orange))
            Text(text).font(.callout)
        }
    }

    private func openRimeDirectory() {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Rime")
        NSWorkspace.shared.open(url)
    }
}
