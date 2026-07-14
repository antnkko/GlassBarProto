import SwiftUI

private typealias D = Metrics.Dumped

/// The big blue confirm button (Figma 3071:6749): 96×96 vibrant circle, white up-arrow
/// (`ArrowUp32Shape`, from the user-supplied SVG). While `loading`, the arrow is replaced by a white
/// `SpinnerLoader` (Figma 3066-5842). Native `PressFadeStyle` press feedback.
struct DumpedFAB: View {
    var action: () -> Void = {}
    var loading: Bool = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(NumoColor.vibrant)
                ZStack {
                    if loading {
                        SpinnerLoader(lineWidth: D.fabArrowStroke)
                            .transition(.opacity)
                    } else {
                        ArrowUp32Shape()
                            .stroke(NumoColor.white,
                                    style: StrokeStyle(lineWidth: D.fabArrowStroke,
                                                       lineCap: .round, lineJoin: .round))
                            .transition(.opacity)
                    }
                }
                .frame(width: D.fabArrowW, height: D.fabArrowH)
                .animation(.easeInOut(duration: 0.25), value: loading)
            }
            .frame(width: D.fabSize, height: D.fabSize)
        }
        .buttonStyle(PressFadeStyle())
    }
}

/// Spinner from Figma 3066-5842 — a faint full ring + a ~¾ bright arc (round cap) rotating continuously.
/// Two `Circle` strokes (the `loader.svg` recreated natively); white, sized to sit inside the FAB.
struct SpinnerLoader: View {
    var lineWidth: CGFloat
    var color: Color = NumoColor.white
    @State private var spin = false

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle().trim(from: 0, to: 0.72)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(spin ? 360 : 0))
        }
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}
