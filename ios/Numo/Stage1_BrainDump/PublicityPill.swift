import SwiftUI

/// "Public/Private" pill. Public (default): bg skin `light`, vibrant announcement icon +
/// label (title.wide16) + down chevron. `TaskConsole.tsx` (TaskPublicity).
struct PublicityPill: View {
    var isPublic: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Image("announcement")
                    .renderingMode(.template)
                    .resizable().scaledToFit()
                    .frame(width: Metrics.pillIcon, height: Metrics.pillIcon)
                    .foregroundStyle(NumoColor.vibrant)

                HStack(spacing: Metrics.pillTextChevronGap) {
                    Text(isPublic ? "Public" : "Private")
                        .font(NumoFont.titleWide16)
                        .foregroundStyle(NumoColor.vibrant)
                    Image("downchevron")
                        .renderingMode(.template)
                        .resizable().scaledToFit()
                        .frame(width: Metrics.pillChevron, height: Metrics.pillChevron)
                        .foregroundStyle(NumoColor.vibrant)
                }
                .padding(.leading, Metrics.pillGap)
            }
            .padding(.leading, Metrics.pillPadLeading)
            .padding(.trailing, Metrics.pillPadTrailing)
            .padding(.vertical, Metrics.pillPadV)
            .background(isPublic ? NumoColor.skinLight : NumoColor.grayAlmost)
            .clipShape(Capsule())
        }
        .buttonStyle(PressFadeStyle())
    }
}
