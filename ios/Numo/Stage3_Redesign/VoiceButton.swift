import GlassTabBar
import SwiftUI

private typealias R = Metrics.Redesign

/// Vibrant voice-entry button in the redesign's bottom bar (Figma 1081:7464):
/// three white voice-wave bars over the accent Liquid Glass material — the
/// same GlassButton the plus/CTA use, so it stretches and its rim reacts on
/// press identically. Keeps its 20pt rounded-rect shape and the white bars.
struct VoiceButton: View {
    let config: GlassTabBarConfig
    var action: () -> Void = {}

    var body: some View {
        GlassButton(RoundedRectangle(cornerRadius: R.voiceRadius, style: .continuous),
                    kind: .accent, config: config, interaction: .tap(action)) {
            HStack(spacing: R.voiceBarSpacing) {
                ForEach(Array(R.voiceBarHeights.enumerated()), id: \.offset) { _, height in
                    Capsule()
                        .fill(NumoColor.white)
                        .frame(width: R.voiceBarWidth, height: height)
                }
            }
            .frame(width: R.voiceSize.width, height: R.voiceSize.height)
        }
    }
}
