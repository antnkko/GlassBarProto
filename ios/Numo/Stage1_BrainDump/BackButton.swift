import SwiftUI

/// 48×48 circular back button, bg gray.almost, grayDarkish chevron. `TaskConsole.tsx`.
struct BackButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image("back")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Metrics.backIcon, height: Metrics.backIcon)
                .foregroundStyle(NumoColor.grayDarkish)
                .frame(width: Metrics.backSize, height: Metrics.backSize)
                .background(NumoColor.grayAlmost)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.backRadius, style: .continuous))
        }
        .buttonStyle(PressFadeStyle())
    }
}
