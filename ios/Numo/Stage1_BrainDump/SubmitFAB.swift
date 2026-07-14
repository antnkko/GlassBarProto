import SwiftUI

/// Floating submit button. RN: 80×80, radius 40, bg vibrant, white up-arrow (stroke 4),
/// soft drop shadow (offset y12, opacity .16). `TaskForm.tsx`.
struct SubmitFAB: View {
    var enabled: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(NumoColor.vibrant)
                UpArrowShape()
                    .stroke(NumoColor.white,
                            style: StrokeStyle(lineWidth: Metrics.fabArrowStroke, lineCap: .round, lineJoin: .round))
                    .frame(width: Metrics.fabArrowW, height: Metrics.fabArrowH)
            }
            .frame(width: Metrics.fabSize, height: Metrics.fabSize)
            .shadow(color: NumoColor.black.opacity(0.16), radius: 18, x: 0, y: 12)
        }
        .buttonStyle(PressFadeStyle())
    }
}
