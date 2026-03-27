import SwiftUI

/// Renders a realistic preview of the Squirrel candidate window
struct CandidatePreview: View {
    let scheme: RimeColorScheme?
    let style: StyleConfig
    let strings: AppStrings
    let previewCandidates = ["你好", "拟好", "泥濠", "倪浩", "逆号"]
    let previewLabels      = ["1", "2", "3", "4", "5"]
    let selectedIndex      = 0
    let preeditText        = "ni hao"

    private var isHorizontal: Bool { style.candidateListLayout == "linear" }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(style.translucency ? 0.72 : 0.5))

            if style.inlineCandidate {
                inlineCandidatePreview
            } else {
                candidateWindow
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110)
    }

    private var candidateWindow: some View {
        VStack(alignment: .leading, spacing: 0) {
            if style.inlinePreedit {
                Text(orientedText(preeditText))
                    .font(.system(size: CGFloat(style.fontPoint) * 0.85))
                    .foregroundColor(rimeColor(scheme?.hilitedTextColor, fallback: .primary))
                    .padding(.horizontal, horizontalInset)
                    .padding(.top, verticalInset)
                    .padding(.bottom, 2)
            }

            if isHorizontal {
                horizontalCandidates
            } else {
                verticalCandidates
            }

            if style.showPaging {
                pagingBar
                    .padding(.horizontal, horizontalInset)
                    .padding(.bottom, max(verticalInset - 2, 4))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius))
                .fill(rimeColor(scheme?.backColor, fallback: Color(nsColor: .controlBackgroundColor)).opacity(style.translucency ? 0.84 : 1.0))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius))
                .stroke(
                    rimeColor(scheme?.borderColor, fallback: Color.secondary.opacity(0.3)),
                    lineWidth: CGFloat(max(style.borderWidth, 0) + 1)
                )
        )
        .shadow(color: .black.opacity(0.25), radius: CGFloat(style.shadowSize + 3), x: 0, y: 2)
        .padding(20)
    }

    private var inlineCandidatePreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(strings.previewInlineTitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 2, height: 26)

                HStack(spacing: 10) {
                    Text(preeditText)
                        .font(.system(size: CGFloat(style.fontPoint) * 0.85))
                        .foregroundStyle(.secondary)

                    HStack(spacing: CGFloat(max(style.spacing, 4))) {
                        ForEach(Array(previewCandidates.prefix(3).enumerated()), id: \.0) { idx, text in
                            candidateCell(index: idx, text: text)
                        }
                    }
                }
            }
            .padding(.horizontal, horizontalInset)
            .padding(.vertical, max(verticalInset, 8))
            .background(
                RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius))
                    .fill(rimeColor(scheme?.backColor, fallback: Color(nsColor: .controlBackgroundColor)).opacity(style.translucency ? 0.84 : 1.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius))
                    .stroke(rimeColor(scheme?.borderColor, fallback: Color.secondary.opacity(0.3)), lineWidth: CGFloat(max(style.borderWidth, 0) + 1))
            )
            .shadow(color: .black.opacity(0.18), radius: CGFloat(style.shadowSize + 2), x: 0, y: 2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Candidate Lists

    private var horizontalCandidates: some View {
        HStack(spacing: CGFloat(style.spacing)) {
            ForEach(Array(previewCandidates.prefix(5).enumerated()), id: \.0) { idx, text in
                candidateCell(index: idx, text: text)
            }
        }
        .padding(.horizontal, horizontalInset)
        .padding(.vertical, verticalInset)
    }

    private var verticalCandidates: some View {
        VStack(alignment: .leading, spacing: CGFloat(style.lineSpacing)) {
            ForEach(Array(previewCandidates.prefix(5).enumerated()), id: \.0) { idx, text in
                candidateCell(index: idx, text: text)
            }
        }
        .padding(.horizontal, horizontalInset)
        .padding(.vertical, verticalInset)
    }

    private func candidateCell(index: Int, text: String) -> some View {
        let isSelected = index == selectedIndex
        let bgColor = isSelected
            ? rimeColor(scheme?.hilitedCandidateBackColor, fallback: Color.accentColor.opacity(0.2))
            : Color.clear
        let textColor = isSelected
            ? rimeColor(scheme?.hilitedCandidateTextColor, fallback: Color.primary)
            : rimeColor(scheme?.candidateTextColor, fallback: Color.primary)
        let labelColor = rimeColor(scheme?.labelColor, fallback: Color.secondary)

        return HStack(alignment: .top, spacing: 4) {
            Text(previewLabels[index])
                .font(.system(size: CGFloat(style.labelFontPoint)))
                .foregroundColor(labelColor)
            Text(orientedText(text))
                .font(.custom(style.fontFace, size: CGFloat(style.fontPoint)))
                .foregroundColor(textColor)
                .multilineTextAlignment(style.textOrientation == "vertical" ? .center : .leading)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: CGFloat(style.hiliteCornerRadius))
                .fill(bgColor)
        )
    }

    private var pagingBar: some View {
        HStack(spacing: 8) {
            Spacer()
            Image(systemName: "chevron.left")
            Text(strings.pagingIndicator)
                .font(.caption.monospacedDigit())
            Image(systemName: "chevron.right")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    // MARK: - Color Helper

    private func rimeColor(_ color: RimeColor?, fallback: Color) -> Color {
        guard let c = color, c.rawValue != 0 else { return fallback }
        return c.swiftUIColor
    }

    private var horizontalInset: CGFloat {
        CGFloat(max(style.borderWidth, 0) + 10)
    }

    private var verticalInset: CGFloat {
        CGFloat(max(style.borderHeight, 0) + 6)
    }

    private func orientedText(_ text: String) -> String {
        guard style.textOrientation == "vertical" else { return text }
        return text.map(String.init).joined(separator: "\n")
    }
}
