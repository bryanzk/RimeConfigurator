import SwiftUI

struct AppearanceView: View {
    @EnvironmentObject var config: ConfigManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                actionBar

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

    private var actionBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(config.strings.appearanceTitle)
                    .font(.title3.weight(.semibold))
                Text(config.strings.appearanceDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(config.strings.resetAppearanceDefaults) {
                config.resetAppearanceDefaults()
            }
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(config.strings.previewTitle, systemImage: "eye")
            CandidatePreview(
                scheme: config.currentColorScheme,
                style:  config.style,
                strings: config.strings
            )
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .unemphasizedSelectedContentBackgroundColor).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(config.strings.previewCoverage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Color Scheme

    private var colorSchemeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(config.strings.colorSchemes, systemImage: "paintpalette")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                ForEach(config.colorSchemes) { scheme in
                    ColorSchemeCard(
                        scheme: scheme,
                        isSelected: scheme.id == config.style.colorScheme,
                        strings: config.strings
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
            sectionHeader(config.strings.fontSettings, systemImage: "textformat")

            VStack(spacing: 10) {
                fontRow(
                    title: config.strings.candidateFont,
                    selection: $config.style.fontFace,
                    size: $config.style.fontPoint,
                    range: 10...32
                )
                fontRow(
                    title: config.strings.labelFont,
                    selection: $config.style.labelFontFace,
                    size: $config.style.labelFontPoint,
                    range: 8...28
                )
            }
        }
    }

    // MARK: - Layout

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(config.strings.layoutTitle, systemImage: "rectangle.split.1x2")

            HStack(spacing: 20) {
                // Candidate list layout
                VStack(alignment: .leading, spacing: 6) {
                    Text(config.strings.candidateLayout).foregroundColor(.secondary)
                    Picker("", selection: $config.style.candidateListLayout) {
                        Label(config.strings.vertical, systemImage: "list.bullet").tag("stacked")
                        Label(config.strings.horizontal, systemImage: "list.bullet.indent").tag("linear")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }

                // Text orientation
                VStack(alignment: .leading, spacing: 6) {
                    Text(config.strings.textDirection).foregroundColor(.secondary)
                    Picker("", selection: $config.style.textOrientation) {
                        Label(config.strings.horizontal, systemImage: "text.alignleft").tag("horizontal")
                        Label(config.strings.vertical, systemImage: "text.alignright").tag("vertical")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
            }

            // Toggles
            HStack(spacing: 24) {
                Toggle(config.strings.inlinePreedit, isOn: $config.style.inlinePreedit)
                Toggle(config.strings.inlineCandidate, isOn: $config.style.inlineCandidate)
                Toggle(config.strings.translucency, isOn: $config.style.translucency)
                Toggle(config.strings.showPaging, isOn: $config.style.showPaging)
            }
        }
    }

    // MARK: - Geometry

    private var geometrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(config.strings.geometryTitle, systemImage: "ruler")

            Grid(alignment: .leading, verticalSpacing: 10) {
                sliderRow(config.strings.cornerRadius,
                          value: $config.style.cornerRadius,
                          range: 0...20, unit: "px")
                sliderRow(config.strings.hiliteCornerRadius,
                          value: $config.style.hiliteCornerRadius,
                          range: 0...20, unit: "px")
                sliderRow(config.strings.borderHeight,
                          value: $config.style.borderHeight,
                          range: -4...20, unit: "px")
                sliderRow(config.strings.borderWidth,
                          value: $config.style.borderWidth,
                          range: -4...20, unit: "px")
                sliderRow(config.strings.lineSpacing,
                          value: $config.style.lineSpacing,
                          range: 0...20, unit: "px")
                sliderRow(config.strings.spacing,
                          value: $config.style.spacing,
                          range: 0...30, unit: "px")
                sliderRow(config.strings.shadowSize,
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

    private func fontRow(
        title: String,
        selection: Binding<String>,
        size: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            FontPicker(selection: selection)
                .frame(minWidth: 180, maxWidth: 260)

            Spacer(minLength: 12)

            Stepper(value: size, in: range) {
                Text("\(size.wrappedValue) pt")
                    .frame(width: 52, alignment: .trailing)
                    .monospacedDigit()
            }
            .fixedSize()
        }
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
        }
    }
}

// MARK: - Color Scheme Card

struct ColorSchemeCard: View {
    let scheme: RimeColorScheme
    let isSelected: Bool
    let strings: AppStrings
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
                    Text(strings.candidateSample)
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
                    Text(strings.highlightSample)
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
