import SwiftUI

/// Renders a realistic preview of the Squirrel candidate window
struct CandidatePreview: View {
    let scheme: RimeColorScheme?
    let style: StyleConfig
    let previewCandidates = ["你好", "拟好", "泥濠", "倪浩", "逆号"]
    let previewLabels      = ["1", "2", "3", "4", "5"]
    let selectedIndex      = 0
    let preeditText        = "ni hao"

    private var isHorizontal: Bool { style.candidateListLayout == "linear" }

    var body: some View {
        ZStack {
            // Blurred background for context
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.5))

            // Candidate window
            VStack(alignment: .leading, spacing: 0) {
                // Preedit bar
                if style.inlinePreedit {
                    Text(preeditText)
                        .font(.system(size: CGFloat(style.fontPoint) * 0.85))
                        .foregroundColor(rimeColor(scheme?.hilitedTextColor, fallback: .primary))
                        .padding(.horizontal, 10)
                        .padding(.top, 6)
                        .padding(.bottom, 2)
                }

                // Candidates
                if isHorizontal {
                    horizontalCandidates
                } else {
                    verticalCandidates
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius))
                    .fill(rimeColor(scheme?.backColor, fallback: Color(nsColor: .controlBackgroundColor)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius))
                    .stroke(rimeColor(scheme?.borderColor, fallback: Color.secondary.opacity(0.3)),
                            lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: CGFloat(style.shadowSize + 3), x: 0, y: 2)
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
    }

    // MARK: - Candidate Lists

    private var horizontalCandidates: some View {
        HStack(spacing: CGFloat(style.spacing)) {
            ForEach(Array(previewCandidates.prefix(5).enumerated()), id: \.0) { idx, text in
                candidateCell(index: idx, text: text)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var verticalCandidates: some View {
        VStack(alignment: .leading, spacing: CGFloat(style.lineSpacing)) {
            ForEach(Array(previewCandidates.prefix(5).enumerated()), id: \.0) { idx, text in
                candidateCell(index: idx, text: text)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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

        return HStack(spacing: 4) {
            Text(previewLabels[index])
                .font(.system(size: CGFloat(style.labelFontPoint)))
                .foregroundColor(labelColor)
            Text(text)
                .font(.custom(style.fontFace, size: CGFloat(style.fontPoint)))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: CGFloat(style.hiliteCornerRadius))
                .fill(bgColor)
        )
    }

    // MARK: - Color Helper

    private func rimeColor(_ color: RimeColor?, fallback: Color) -> Color {
        guard let c = color, c.rawValue != 0 else { return fallback }
        return c.swiftUIColor
    }
}
