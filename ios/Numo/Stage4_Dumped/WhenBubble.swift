import SwiftUI

private typealias D = Metrics.Dumped

/// The "when" speech bubble: a rounded bubble with a small tail, tinted to the item's accent,
/// holding a single-line date (e.g. "Tomorrow"). The caller tilts it ∓0.75°. Redrawn natively
/// as a `Shape` so it recolors per item-family and animates cleanly.
struct WhenBubble: View {
    let text: String
    let accent: Color

    var body: some View {
        Text(text)
        .font(NumoFont.obviouslyMedium(D.whenTextSize))
        .foregroundStyle(accent)
        .padding(.horizontal, D.whenPadH)
        .padding(.vertical, D.whenPadV)
        .background(
            // Negative bottom padding lets the tail poke just below the text box without
            // affecting layout; the shape draws its body in the top region, tail beneath.
            SpeechBubble(radius: D.whenRadius, tail: D.whenTail)
                .fill(accent.opacity(D.whenFillOpacity))
                .padding(.bottom, -D.whenTail)
        )
    }
}

/// Rounded-rect bubble body with a small downward tail at the bottom-leading corner.
struct SpeechBubble: Shape {
    var radius: CGFloat
    var tail: CGFloat

    func path(in rect: CGRect) -> Path {
        let body = CGRect(x: rect.minX, y: rect.minY,
                          width: rect.width, height: max(0, rect.height - tail))
        var p = Path(roundedRect: body,
                     cornerSize: CGSize(width: radius, height: radius),
                     style: .continuous)

        let baseX = body.minX + radius + 2
        let baseY = body.maxY
        var t = Path()
        t.move(to: CGPoint(x: baseX, y: baseY - tail))
        t.addLine(to: CGPoint(x: baseX - tail, y: baseY + tail))      // point: down-left
        t.addLine(to: CGPoint(x: baseX + tail * 1.6, y: baseY - tail * 0.4))
        t.closeSubpath()
        p.addPath(t)
        return p
    }
}
