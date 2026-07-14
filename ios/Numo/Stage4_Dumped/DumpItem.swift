import SwiftUI

private typealias D = Metrics.Dumped

/// One row of the dumped list (Figma 3066:5739/5740/5741). Leading family-tinted glyph
/// (28, 20% opacity) + content: task/routine show a title, tag chip, and when-bubble;
/// the note shows masked prose that fades out at the bottom.
struct DumpItem: View {
    let entry: DumpEntry
    /// Entrance: each child reveals (blur + slide) on its own stagger off `baseDelay`. The item's
    /// white bg/padding stay put — they're revealed by the card sliding up.
    var appeared: Bool = true
    var baseDelay: Double = 0

    private func childDelay(_ i: Int) -> Double { baseDelay + Double(i) * DumpedEntrance.childStagger }

    var body: some View {
        HStack(alignment: .top, spacing: D.itemIconGap) {
            glyph
                .frame(width: D.glyph, height: D.glyph)
                .opacity(D.glyphOpacity)
                .reveal(appeared, delay: childDelay(0))

            if entry.kind == .note {
                noteContent
            } else {
                rowContent
            }
        }
        .padding(.horizontal, D.itemPadH)
        .padding(.vertical, D.itemPadV)
        .frame(width: D.cardWidth, alignment: .leading)
        .background(NumoColor.white)
    }

    // MARK: leading glyph

    @ViewBuilder private var glyph: some View {
        switch entry.kind {
        case .task:
            // Empty checkbox — the exact squircle from `checkbox.svg` (23×23 inset in a 28 box).
            CheckboxSquircle()
                .stroke(entry.kind.glyphColor, lineWidth: D.checkboxStroke)
        case .routine:
            templateIcon("repeat_icon")
        case .note:
            templateIcon("note_icon")
        }
    }

    private func templateIcon(_ name: String) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(entry.kind.glyphColor)
    }

    // MARK: task / routine content

    private var rowContent: some View {
        HStack(alignment: .center, spacing: D.itemContentGap) {
            VStack(alignment: .leading, spacing: D.titleTagGap) {
                Text(entry.title)
                    .font(NumoFont.obviouslyMedium(D.titleTextSize))
                    .foregroundStyle(entry.kind.titleColor)
                    .reveal(appeared, delay: childDelay(1))

                if let label = entry.tagLabel {
                    DumpTagChip(label: label, counter: entry.tagCounter)
                        .rotationEffect(.degrees(entry.kind == .task ? -D.rowRotation : D.rowRotation))
                        .reveal(appeared, delay: childDelay(2))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let when = entry.when {
                WhenBubble(text: when, accent: entry.kind.whenColor)
                    .rotationEffect(.degrees(entry.kind == .task ? D.rowRotation : -D.rowRotation))
                    .reveal(appeared, delay: childDelay(3))
            }
        }
    }

    // MARK: note content (two lines; long line 2 overflows and fades out on the right)

    private var noteContent: some View {
        let parts = (entry.body ?? "").split(separator: "\n", maxSplits: 1,
                                             omittingEmptySubsequences: false)
        let line1 = parts.first.map(String.init) ?? ""
        let line2 = parts.count > 1 ? String(parts[1]) : ""

        return VStack(alignment: .leading, spacing: D.titleLineSpacing) {
            Text(line1)
            Text(line2)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)   // let it overflow, then clip + fade
        }
        .font(NumoFont.obviouslyMedium(D.titleTextSize))
        .foregroundStyle(entry.kind.titleColor)
        .frame(width: D.noteMaxWidth, alignment: .leading)
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: D.noteFadeStart),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .reveal(appeared, delay: childDelay(1))
    }
}

/// The empty checkbox — a continuous squircle, translated 1:1 from `checkbox.svg` (28 viewBox,
/// 23×23 square inset 2.5). Stroke it (glyph colour @ glyphOpacity).
struct CheckboxSquircle: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 28, sy = rect.height / 28
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var path = Path()
        path.move(to: p(2.5, 14))
        path.addCurve(to: p(14, 2.5),  control1: p(2.5, 4.52975),   control2: p(4.52975, 2.5))
        path.addCurve(to: p(25.5, 14), control1: p(23.4703, 2.5),   control2: p(25.5, 4.52975))
        path.addCurve(to: p(14, 25.5), control1: p(25.5, 23.4703),  control2: p(23.4703, 25.5))
        path.addCurve(to: p(2.5, 14),  control1: p(4.52975, 25.5),  control2: p(2.5, 23.4703))
        path.closeSubpath()
        return path
    }
}
