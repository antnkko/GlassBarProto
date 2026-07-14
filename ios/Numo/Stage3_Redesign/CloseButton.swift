import SwiftUI

private typealias R = Metrics.Redesign

/// 48×48 white circular close button with a soft halo shadow + faint outer ring.
/// Redesign counterpart of Stage 1's `BackButton` (Figma 1128:14567).
struct CloseButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image("cross")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: R.crossIcon, height: R.crossIcon)
                .foregroundStyle(NumoColor.grayNight)
                .frame(width: R.closeSize, height: R.closeSize)
                .ghostSurface(Circle())
        }
        .buttonStyle(PressFadeStyle())
    }
}
