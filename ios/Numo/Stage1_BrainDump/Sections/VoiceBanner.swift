import SwiftUI

/// Top promo banner ("Switch to Ai voice mode") — gradient image bg, top corners radius 36,
/// overlaps the card below by 64. Mirrors `TasksVoiceBrainDumpBanner.tsx`.
struct VoiceBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("Switch to Ai voice mode")
                .font(NumoFont.titleWide16)
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer(minLength: 0)
            Image("micro_28")
                .renderingMode(.template)
                .resizable().scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Metrics.bannerPadH)
        .padding(.top, Metrics.bannerPadTop)
        .padding(.bottom, Metrics.bannerPadBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Metrics.bannerHeight, alignment: .top)
        .background {
            Image("welcome_bg")
                .resizable()
                .scaledToFill()
                // Light, left-biased scrim: keeps the label legible without darkening the painting.

        }
        .clipShape(.rect(topLeadingRadius: Metrics.cardRadius, topTrailingRadius: Metrics.cardRadius))
    }
}
