import SwiftUI

/// Geometry/feel for the segmented "pill switch" (Figma 1112:8687).
enum SegSwitch {
    static let thumbHeight: CGFloat = 38      // selected pill (Figma chip h-38)
    static let pad: CGFloat = 3               // track inset → overall height 44
    static let font: CGFloat = 16             // Obviously-Semibold
    static let textLift: CGFloat = 4          // optical centering (Figma chip pb-4)
    static let shadowRadius: CGFloat = 5      // CSS drop-shadow blur 10 → radius 5
    static let shadowOpacity: Double = 0.1    // black @ 10%
    /// The thumb slide + text cross-fade.
    static let spring: Animation = .snappy(duration: 0.35, extraBounce: 0.12)
}

/// A native segmented "pill switch": a `grayAlmost` track with a white **thumb** that slides to the
/// tapped segment via `matchedGeometryEffect` (exactly one source per id), while the segment labels
/// cross-fade `ink`↔`grayNight` on the same spring. Figma 1112:8687.
struct SegmentedSwitch: View {
    let labels: [String]
    @Binding var selection: Int
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self) { i in
                Button {
                    withAnimation(SegSwitch.spring) { selection = i }
                } label: {
                    Text(labels[i])
                        .font(NumoFont.obviouslySemibold(SegSwitch.font))
                        .foregroundStyle(selection == i ? NumoColor.ink : NumoColor.grayNight)
                        .padding(.bottom, SegSwitch.textLift)
                        .frame(maxWidth: .infinity)
                        .frame(height: SegSwitch.thumbHeight)
                        .background {
                            if selection == i {
                                Capsule(style: .continuous)
                                    .fill(NumoColor.white)
                                    .shadow(color: .black.opacity(SegSwitch.shadowOpacity),
                                            radius: SegSwitch.shadowRadius)
                                    .matchedGeometryEffect(id: "thumb", in: ns)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(SegSwitch.pad)
        .background(Capsule(style: .continuous).fill(NumoColor.grayAlmost))
    }
}
