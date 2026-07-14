import SwiftUI

private typealias R = Metrics.Redesign

/// "Routine | When" twin-chip card in the redesign's bottom bar (Figma 1097:8001).
/// The **When** chip opens the "When" picker; **Routine** is still decorative (its picker
/// is a later session).
struct RoutineTimeCard: View {
    var onWhenTap: () -> Void = {}
    /// `bare` drops the ghost-surface shell so a shared container (the When-picker morph)
    /// can own one continuous shell around the chips + picker content.
    var bare: Bool = false

    var body: some View {
        if bare {
            chips
        } else {
            chips.ghostSurface(RoundedRectangle(cornerRadius: R.cardRadius, style: .continuous))
        }
    }

    private var chips: some View {
        HStack(spacing: 0) {
            chip(icon: "repeat_icon", label: "Routine")
            Capsule()
                .fill(NumoColor.grayAlmost)
                .frame(width: R.cardDividerSize.width, height: R.cardDividerSize.height)
            Button(action: onWhenTap) {
                chip(icon: "clock_icon", label: "When")
            }
            .buttonStyle(PressFadeStyle())
        }
        .frame(maxWidth: .infinity)
        .frame(height: R.cardHeight)
    }

    private func chip(icon: String, label: String) -> some View {
        VStack(spacing: R.cardIconLabelGap) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: R.cardIcon, height: R.cardIcon)
                .foregroundStyle(NumoColor.grayNight)
            Text(label)
                .font(NumoFont.bodyWide16)
                .foregroundStyle(NumoColor.ink)
        }
        .frame(maxWidth: .infinity)
        .frame(height: R.cardHeight)
        .contentShape(Rectangle())
    }
}
