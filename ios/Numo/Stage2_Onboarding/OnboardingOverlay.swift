import SwiftUI

/// Stage 2 — the onboarding overlay shown over the brain dump screen ("Dumping tasks just
/// got better!"). A white-gradient scrim (transparent over the brain dump up top, solid
/// white at the bottom) carrying a title + "See how" CTA. The CTA triggers the Stage 3 morph.
///
/// Ported from Figma node 3303:7419 (Braindump 2.0): overlay 3303:7421, title 3303:7453,
/// button 3303:7456. The frame's background image there is a stand-in for our real brain
/// dump screen, which renders underneath this overlay — so only the scrim + title + CTA
/// are reproduced here.
struct OnboardingOverlay: View {
    @EnvironmentObject private var flow: AppFlowCoordinator

    var body: some View {
        ZStack {
            // White scrim: transparent at ~7% so the brain dump reads through up top,
            // solid white by ~61.5% down (Figma gradient stops), white to the bottom.
            LinearGradient(
                stops: [
                    .init(color: NumoColor.white.opacity(0), location: 0.072),
                    .init(color: NumoColor.white,            location: 0.615),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Title + CTA, anchored to the bottom (inside the solid-white zone).
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                OverlayTitleLabel()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                Button(action: { flow.morphToRedesign() }) {
                    Text("See how")
                        .font(NumoFont.titleWide18)
                        .tracking(0.18)
                        .foregroundStyle(NumoColor.white)
                        .padding(.bottom, 4)        // optical centering — Obviously sits high
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .background(NumoColor.vibrant, in: Capsule())
                }
                .buttonStyle(PressFadeStyle())
                .padding(.top, 36)
                .padding(.horizontal, 48)
            }
            .padding(.bottom, 20)
        }
        // Morph Act I: the overlay gets out of the way fast as the bow-stretch begins.
        // Keyed to the Bool so the stretching→released change doesn't retarget it.
        .opacity(flow.morphPhase == .idle ? 1 : 0)
        .animation(.easeOut(duration: MorphChoreo.overlayFadeOut), value: flow.morphPhase == .idle)
    }
}

/// "Dumping tasks just got better!" — ObviouslyNarrow-Bold 40 with the design's exact 46pt
/// line height + 0.8 tracking. SwiftUI `Text` can't tighten line height below the font's
/// loose natural leading, so we render through a UILabel (same pattern as the console
/// placeholder in `ConsoleCard`).
private struct OverlayTitleLabel: UIViewRepresentable {
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.minimumLineHeight = 46
        style.maximumLineHeight = 46

        let font = UIFont(name: "ObviouslyNarrow-Bold", size: 40) ?? .systemFont(ofSize: 40, weight: .bold)
        label.attributedText = NSAttributedString(
            string: "Dumping tasks\njust got better!",
            attributes: [
                .font: font,
                .foregroundColor: UIColor(NumoColor.text),
                .kern: 0.8,
                .paragraphStyle: style,
            ]
        )
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {}
}

#Preview {
    ZStack {
        NumoColor.vibrant.ignoresSafeArea()
        OnboardingOverlay()
            .environmentObject(AppFlowCoordinator())
    }
}
