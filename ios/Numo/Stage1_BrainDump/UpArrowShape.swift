import SwiftUI

/// FAB up-arrow, ported from `../RN Codebase/assets/ArrowUp.svg` (viewBox 28×36).
/// Path: M14 34 V2  ·  M14 2 → 2 14  ·  M14 2 → 26 14
struct UpArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 28, sy = rect.height / 36
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var p = Path()
        p.move(to: pt(14, 34)); p.addLine(to: pt(14, 2))   // stem
        p.move(to: pt(14, 2));  p.addLine(to: pt(2, 14))   // left wing
        p.move(to: pt(14, 2));  p.addLine(to: pt(26, 14))  // right wing
        return p
    }
}
