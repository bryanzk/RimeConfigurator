import SwiftUI

struct BehaviorView: View {
    @EnvironmentObject var config: ConfigManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                pageSizeSection
                Divider()
                inputModeSection
                Divider()
                appOverrideHintSection
            }
            .padding(24)
        }
    }

    // MARK: - Page Size

    private var pageSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("每页候选词数量", systemImage: "list.number")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(1...9, id: \.self) { n in
                    pageSizeButton(n)
                }
            }

            Text("当前设置：每页显示 \(config.behavior.pageSize) 个候选词")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func pageSizeButton(_ n: Int) -> some View {
        let selected = config.behavior.pageSize == n
        return Button(action: { config.behavior.pageSize = n }) {
            Text("\(n)")
                .frame(width: 36, height: 36)
                .font(.system(size: 15, weight: selected ? .semibold : .regular))
                .foregroundColor(selected ? .white : .primary)
                .background(
                    Circle()
                        .fill(selected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    Circle()
                        .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.3),
                                lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Input Mode

    private var inputModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("输入行为", systemImage: "keyboard")
                .font(.headline)

            VStack(spacing: 0) {
                behaviorToggleRow(
                    title: "在线预编辑",
                    subtitle: "在光标处直接显示正在输入的拼音，不弹出单独的预编辑框",
                    binding: $config.style.inlinePreedit,
                    icon: "text.cursor"
                )
                Divider().padding(.leading, 52)
                behaviorToggleRow(
                    title: "候选词内嵌",
                    subtitle: "候选词直接内嵌在光标位置，不显示候选窗口",
                    binding: $config.style.inlineCandidate,
                    icon: "rectangle.inset.filled"
                )
                Divider().padding(.leading, 52)
                behaviorToggleRow(
                    title: "磨砂透明效果",
                    subtitle: "候选窗口背景使用半透明磨砂效果（需要系统支持）",
                    binding: $config.style.translucency,
                    icon: "circle.lefthalf.filled.righthalf.striped.horizontal"
                )
                Divider().padding(.leading, 52)
                behaviorToggleRow(
                    title: "显示翻页按钮",
                    subtitle: "在候选窗口中显示上一页/下一页的箭头按钮",
                    binding: $config.style.showPaging,
                    icon: "chevron.left.chevron.right"
                )
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func behaviorToggleRow(
        title: String,
        subtitle: String,
        binding: Binding<Bool>,
        icon: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: binding)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - App Override Hint

    private var appOverrideHintSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("按应用覆盖配置", systemImage: "app.badge.checkmark")
                .font(.headline)

            Text("""
                鼠须管支持针对特定应用程序设置不同的行为，例如在终端中自动切换为英文模式。\
                如需配置，请直接编辑 squirrel.custom.yaml 中的 app_options 节。
                """)
                .font(.callout)
                .foregroundColor(.secondary)

            Button("在访达中打开配置目录") {
                NSWorkspace.shared.open(
                    FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Library/Rime")
                )
            }
            .buttonStyle(.link)
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
