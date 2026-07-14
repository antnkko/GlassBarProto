import SwiftUI

/// White rounded card matching RN `Wrapper` (padding 32, radius 36, minHeight 92, edge-to-edge).
struct SectionCard<Content: View>: View {
    var paddingH: CGFloat = Metrics.cardPadding
    var paddingV: CGFloat = Metrics.cardPadding
    var content: Content

    init(paddingH: CGFloat = Metrics.cardPadding,
         paddingV: CGFloat = Metrics.cardPadding,
         @ViewBuilder content: () -> Content) {
        self.paddingH = paddingH
        self.paddingV = paddingV
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, paddingH)
            .padding(.vertical, paddingV)
            .frame(minHeight: Metrics.cardMinHeight, alignment: .topLeading)
            .background(NumoColor.white)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
    }
}

/// Icon + title row shared by most section cards (vibrant, title.wide18).
struct SectionHeader: View {
    var icon: String
    var title: String

    var body: some View {
        HStack(spacing: Metrics.headerIconGap) {
            Image(icon)
                .renderingMode(.template)
                .resizable().scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(NumoColor.vibrant)
            Text(title)
                .font(NumoFont.titleWide18)
                .foregroundStyle(NumoColor.vibrant)
        }
    }
}
