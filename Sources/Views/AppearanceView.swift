import SwiftUI

struct AppearanceView: View {
    @EnvironmentObject var config: ConfigManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Preview
                previewSection

                Divider()

                // Color Scheme
                colorSchemeSection

                Divider()

                // Font
                fontSection

                Divider()

                // Layout
                layoutSection

                Divider()

                // Geometry
                geometrySection
            }
            .padding(24)
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("候选窗口预览", systemImage: "eye")
                .font(.headline)
            CandidatePreview(
                scheme: config.currentColorScheme,
                style:  config.style
            )
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .unemphasizedSelectedContentBackgroundColor).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Color Scheme

    private var colorSchemeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("颜色方案", systemImage: "paintpalette")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                ForEach(config.colorSchemes) { scheme in
                    ColorSchemeCard(
                        scheme: scheme,
                        isSelected: scheme.id == config.style.colorScheme
                    ) {
                        config.style.colorScheme = scheme.id
                    }
                }
            }
        }
    }

    // MARK: - Font

    private var fontSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("字体设置", systemImage: "textformat")
                .font(.headline)

            Grid(alignment: .leading, verticalSpacing: 10) {
                GridRow {
                    Text("候选词字体")
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        FontPicker(selection: $config.style.fontFace)
                            .frame(maxWidth: 200)
                        Stepper("\(config.style.fontPoint) pt",
                                value: $config.style.fontPoint, in: 10...32)
                    }
                }
                GridRow {
                    Text("标签字体")
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        FontPicker(selection: $config.style.labelFontFace)
                            .frame(maxWidth: 200)
                        Stepper("\(config.style.labelFontPoint) pt",
                                value: $config.style.labelFontPoint, in: 8...28)
                    }
                }
            }
        }
    }

    // MARK: - Layout

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("排列方式", systemImage: "rectangle.split.1x2")
                .font(.headline)

            HStack(spacing: 20) {
                // Candidate list layout
                VStack(alignment: .leading, spacing: 6) {
                    Text("候选词布局").foregroundColor(.secondary)
                    Picker("", selection: $config.style.candidateListLayout) {
                        Label("竖排", systemImage: "list.bullet").tag("stacked")
                        Label("横排", systemImage: "list.bullet.indent").tag("linear")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }

                // Text orientation
                VStack(alignment: .leading, spacing: 6) {
                    Text("文字方向").foregroundColor(.secondary)
                    Picker("", selection: $config.style.textOrientation) {
                        Label("横向", systemImage: "text.alignleft").tag("horizontal")
                        Label("纵向", systemImage: "text.alignright").tag("vertical")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
            }

            // Toggles
            HStack(spacing: 24) {
                Toggle("在线预编辑", isOn: $config.style.inlinePreedit)
                Toggle("候选内嵌", isOn: $config.style.inlineCandidate)
                Toggle("磨砂透明", isOn: $config.style.translucency)
                Toggle("显示翻页", isOn: $config.style.showPaging)
            }
        }
    }

    // MARK: - Geometry

    private var geometrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("尺寸与间距", systemImage: "ruler")
                .font(.headline)

            Grid(alignment: .leading, verticalSpacing: 10) {
                sliderRow("圆角半径",
                          value: $config.style.cornerRadius,
                          range: 0...20, unit: "px")
                sliderRow("高亮圆角",
                          value: $config.style.hiliteCornerRadius,
                          range: 0...20, unit: "px")
                sliderRow("边框高度",
                          value: $config.style.borderHeight,
                          range: -4...20, unit: "px")
                sliderRow("边框宽度",
                          value: $config.style.borderWidth,
                          range: -4...20, unit: "px")
                sliderRow("行间距",
                          value: $config.style.lineSpacing,
                          range: 0...20, unit: "px")
                sliderRow("候选间距",
                          value: $config.style.spacing,
                          range: 0...30, unit: "px")
                sliderRow("阴影大小",
                          value: $config.style.shadowSize,
                          range: 0...20, unit: "px")
            }
        }
    }

    private func sliderRow(_ label: String,
                            value: Binding<Int>,
                            range: ClosedRange<Int>,
                            unit: String) -> some View {
        GridRow {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            HStack(spacing: 8) {
                Slider(value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0) }
                ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
                .frame(width: 180)
                Text("\(value.wrappedValue) \(unit)")
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Color Scheme Card

struct ColorSchemeCard: View {
    let scheme: RimeColorScheme
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Mini candidate preview strip
                miniPreview
                    .frame(height: 36)

                // Name + author
                VStack(alignment: .leading, spacing: 1) {
                    Text(scheme.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    if !scheme.author.isEmpty {
                        Text(scheme.author)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
            }
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected
                    ? Color.accentColor.opacity(0.15)
                    : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1)
        )
        .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private var miniPreview: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(scheme.backColor.swiftUIColor)

            HStack(spacing: 0) {
                // Normal candidate
                HStack(spacing: 3) {
                    Text("1")
                        .font(.system(size: 10))
                        .foregroundColor(scheme.labelColor.rawValue != 0
                            ? scheme.labelColor.swiftUIColor : .secondary)
                    Text("候选")
                        .font(.system(size: 11))
                        .foregroundColor(scheme.candidateTextColor.rawValue != 0
                            ? scheme.candidateTextColor.swiftUIColor : .primary)
                }
                .padding(.horizontal, 5)

                // Highlighted candidate
                HStack(spacing: 3) {
                    Text("2")
                        .font(.system(size: 10))
                        .foregroundColor(scheme.labelColor.rawValue != 0
                            ? scheme.labelColor.swiftUIColor : .secondary)
                    Text("高亮")
                        .font(.system(size: 11))
                        .foregroundColor(scheme.hilitedCandidateTextColor.rawValue != 0
                            ? scheme.hilitedCandidateTextColor.swiftUIColor : .white)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(scheme.hilitedCandidateBackColor.rawValue != 0
                            ? scheme.hilitedCandidateBackColor.swiftUIColor : Color.accentColor)
                )
            }
            .padding(.horizontal, 6)
        }
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 8, bottomLeadingRadius: 0,
            bottomTrailingRadius: 0, topTrailingRadius: 8))
    }
}

// MARK: - Font Picker

struct FontPicker: NSViewRepresentable {
    @Binding var selection: String

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton()
        let families = NSFontManager.shared.availableFontFamilies
        for family in families { button.addItem(withTitle: family) }
        button.selectItem(withTitle: selection)
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectionChanged(_:))
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        button.selectItem(withTitle: selection)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject {
        var parent: FontPicker
        init(_ parent: FontPicker) { self.parent = parent }

        @objc func selectionChanged(_ sender: NSPopUpButton) {
            parent.selection = sender.selectedItem?.title ?? parent.selection
        }
    }
}
