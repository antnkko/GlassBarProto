import SwiftUI

private typealias R = Metrics.Redesign

/// Vibrant voice-entry button in the redesign's bottom bar (Figma 1081:7464):
/// three white voice-wave bars drawn natively. Decorative in the static prototype.
struct VoiceButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: R.voiceBarSpacing) {
                ForEach(Array(R.voiceBarHeights.enumerated()), id: \.offset) { _, height in
                    Capsule()
                        .fill(NumoColor.white)
                        .frame(width: R.voiceBarWidth, height: height)
                }
            }
            .frame(width: R.voiceSize.width, height: R.voiceSize.height)
            .background(
                RoundedRectangle(cornerRadius: R.voiceRadius, style: .continuous)
                    .fill(NumoColor.vibrant)
            )
        }
        .buttonStyle(PressFadeStyle())
    }
}
