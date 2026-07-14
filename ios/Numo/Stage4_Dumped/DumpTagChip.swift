import SwiftUI

private typealias D = Metrics.Dumped

/// The tag chip under a task/routine name: a soft white **rounded capsule** with a small
/// leading dot and a label (+ optional "+N" counter). The caller tilts it ±0.75°.
struct DumpTagChip: View {
    let label: String
    var counter: String? = nil

    var body: some View {
        HStack(spacing: D.chipDotGap) {
            Circle()
                .fill(NumoColor.grayNight)
                .frame(width: D.chipDot, height: D.chipDot)
            Text(labelText)
        }
        .font(NumoFont.obviouslyMedium(D.chipTextSize))
        .padding(.leading, D.chipPadLeading)
        .padding(.trailing, D.chipPadTrailing)
        .padding(.vertical, D.chipPadV)
        .background(
            Capsule(style: .continuous)
                .fill(NumoColor.white)
                .shadow(color: NumoColor.grayNormal.opacity(D.chipShadowOpacity),
                        radius: D.chipShadowBlur, x: 0, y: 1)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(NumoColor.grayNormal.opacity(D.chipBorderOpacity), lineWidth: 1)
        )
    }

    /// "House" (neutralDark) + " +3" (grayNight), as one styled run.
    private var labelText: AttributedString {
        var s = AttributedString(label)
        s.foregroundColor = NumoColor.neutralDark
        if let counter {
            var c = AttributedString(" " + counter)
            c.foregroundColor = NumoColor.grayNight
            s.append(c)
        }
        return s
    }
}
