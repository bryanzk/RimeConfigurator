import SwiftUI

/// 保存成功后弹出的 Sheet：展示写入的 YAML 内容 + 手动部署引导
struct SavedResultSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var config: ConfigManager
    @State private var tab: SheetTab = .squirrel

    enum SheetTab: String, CaseIterable {
        case squirrel = "squirrel.custom.yaml"
        case defaults = "default.custom.yaml"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("配置已写入磁盘").font(.headline)
                    Text("~/Library/Rime/").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button("关闭") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)

            Divider()

            // Deploy instruction banner
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
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 6) {
                Text("需要手动触发「重新部署」才能生效")
                    .font(.headline)

                Text("配置文件已保存，但 RIME 需要重新部署后才会读取新设置。请按以下步骤操作：")
                    .font(.callout)
                    .foregroundColor(.secondary)

                // Steps
                VStack(alignment: .leading, spacing: 4) {
                    stepRow(n: "1", text: "查看菜单栏右侧，找到「鼠」字图标（鼠须管）")
                    stepRow(n: "2", text: "点击该图标，在下拉菜单中选择「重新部署」")
                    stepRow(n: "3", text: "等待 2–3 秒，新设置即刻生效")
                }
                .padding(.top, 2)

                Button(action: openRimeDirectory) {
                    Label("在访达中查看配置文件", systemImage: "folder")
                }
                .buttonStyle(.link)
                .font(.callout)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.08))
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
