import SwiftUI

/// "Tags" — header + example unselected chips + a divider and "Manage" row.
/// Mirrors `TaskTags.tsx` (chips are representative placeholders).
struct TagsSection: View {
    private let tags = ["Work", "Personal", "Health"]

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(icon: "promo_bold", title: "Tags")
                    .padding(.bottom, Metrics.headerBottomTight)

                FlowLayout(spacing: Metrics.chipGap, lineSpacing: 10) {
                    ForEach(tags, id: \.self) { TagChip(label: $0) }
                }
                .padding(.leading, Metrics.tagsIndent)

                VStack(alignment: .leading, spacing: 0) {
                    RoundedRectangle(cornerRadius: Metrics.dividerThickness / 2)
                        .fill(NumoColor.grayAlmost)
                        .frame(height: Metrics.dividerThickness)
                        .padding(.bottom, Metrics.dividerBottom)

                    HStack(spacing: Metrics.headerIconGap) {
                        Image("settings_bold")
                            .renderingMode(.template)
                            .resizable().scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(NumoColor.vibrant)
                        Text("Manage")
                            .font(NumoFont.titleWide18)
                            .foregroundStyle(NumoColor.vibrant)
                    }
                }
                .padding(.top, Metrics.manageTop)
            }
        }
    }
}

/// Pill tag chip. Unselected: transparent w/ gray border + grayNight text. Selected: vibrant fill.
private struct TagChip: View {
    var label: String
    var selected: Bool = false

    var body: some View {
        Text(label)
            .font(NumoFont.bodyWide16)
            .foregroundStyle(selected ? Color.white : NumoColor.grayNight)
            .padding(.horizontal, Metrics.chipPadH)
            .frame(height: Metrics.chipHeight)
            .background(selected ? NumoColor.vibrant : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.chipRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.chipRadius, style: .continuous)
                    .stroke(selected ? NumoColor.vibrant : NumoColor.grayAlmost, lineWidth: Metrics.chipBorder)
            )
    }
}
