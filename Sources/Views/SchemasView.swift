import SwiftUI

struct SchemasView: View {
    @EnvironmentObject var config: ConfigManager
    @State private var searchText = ""

    var filteredDisabled: [SchemaItem] {
        config.disabledSchemas.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                               || $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HSplitView {
            // Left: Enabled schemas (reorderable)
            enabledList
                .frame(minWidth: 260)

            // Right: Available (disabled) schemas
            availableList
                .frame(minWidth: 220)
        }
        .padding(16)
    }

    // MARK: Enabled List

    private var enabledList: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("已启用的输入方案", systemImage: "checkmark.circle.fill", color: .green)
                .padding(.bottom, 8)

            if config.enabledSchemas.isEmpty {
                emptyStateView("暂无已启用方案", subtitle: "从右侧添加输入方案")
            } else {
                List {
                    ForEach(config.enabledSchemas) { schema in
                        EnabledSchemaRow(schema: schema) {
                            withAnimation { config.disableSchema(schema) }
                        }
                    }
                    .onMove { from, to in
                        withAnimation { config.moveSchema(fromOffsets: from, toOffset: to) }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }

            Text("拖动行可调整切换顺序，排在首位的方案将作为默认方案")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 6)
        }
        .padding(.trailing, 8)
    }

    // MARK: Available List

    private var availableList: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("可用方案库", systemImage: "square.grid.2x2", color: .blue)
                .padding(.bottom, 8)

            TextField("搜索方案…", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.bottom, 6)

            if config.availableSchemas.isEmpty {
                emptyStateView("未找到可用方案",
                    subtitle: "请确认 Squirrel 已正确安装\n且 ~/.squirrel/SharedSupport 存在")
            } else if filteredDisabled.isEmpty && !searchText.isEmpty {
                emptyStateView("无匹配结果", subtitle: "尝试其他关键字")
            } else {
                List {
                    if filteredDisabled.isEmpty {
                        Text("所有方案均已启用")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(filteredDisabled) { schema in
                            AvailableSchemaRow(schema: schema) {
                                withAnimation { config.enableSchema(schema) }
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }

            Text("点击 + 将方案添加到已启用列表")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 6)
        }
        .padding(.leading, 8)
    }

    // MARK: Helpers

    private func sectionHeader(_ title: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
        }
    }

    private func emptyStateView(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text(title).font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Enabled Schema Row

struct EnabledSchemaRow: View {
    let schema: SchemaItem
    let onRemove: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .font(.system(size: 12))

            VStack(alignment: .leading, spacing: 1) {
                Text(schema.name)
                    .font(.body)
                Text(schema.id)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0.6)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Available Schema Row

struct AvailableSchemaRow: View {
    let schema: SchemaItem
    let onAdd: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(schema.name)
                    .font(.body)
                Text(schema.id)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0.6)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
