import SwiftUI

/// The Dumped FAB's up-arrow — a translation of the user-supplied `arrow up.svg` (32×32 viewBox):
/// a straight stem with a smooth, curved-chevron head (cubic beziers). Stroke it (white, ~3.5,
/// round caps) — it's an open path, not a fill.
struct ArrowUp32Shape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 32, sy = rect.height / 32
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var path = Path()
        // stem
        path.move(to: p(16, 27.334))
        path.addLine(to: p(16, 4.667))
        // curved chevron head: right point → apex → left point
        path.move(to: p(25.333, 14))
        path.addCurve(to: p(16, 4.667), control1: p(21.444, 8.712), control2: p(16, 4.667))
        path.addCurve(to: p(6.667, 14), control1: p(16, 4.667), control2: p(10.556, 8.712))
        return path
    }
}
