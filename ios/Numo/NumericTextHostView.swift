import SwiftUI
import UIKit

/// Hosts a (label +) value SwiftUI text stack; the value runs the real
/// `.contentTransition(.numericText())` — Apple's per-glyph roll + blur on
/// string change, on the donor spring (response 0.4 / dampingFraction 0.6,
/// the DumpedScreen title). BOTH lines live in ONE SwiftUI VStack (native
/// rowTextGap spacing), so their relative position uses a single font-metric
/// system — an RN-Text label above a SwiftUI value never aligned reliably
/// (Stage 47 lesson). RN pushes strings/fonts via @Published.
final class NumericTextModel: ObservableObject {
    @Published var text = ""
    @Published var fontSize: CGFloat = 17
    @Published var fontFamily = "Obviously-Semibold"
    @Published var color = Color.black
    @Published var tracking: CGFloat = 0
    @Published var label = ""
    @Published var labelFontSize: CGFloat = 14
    @Published var labelFontFamily = "Obviously-Medium"
    @Published var labelColor = Color.gray
    @Published var textGap: CGFloat = -3
}

private struct NumericTextRootView: View {
    @ObservedObject var model: NumericTextModel

    var body: some View {
        VStack(alignment: .leading, spacing: model.textGap) {
            if !model.label.isEmpty {
                Text(model.label)
                    .font(.custom(model.labelFontFamily, size: model.labelFontSize))
                    .foregroundStyle(model.labelColor)
            }
            Text(model.text)
                .font(.custom(model.fontFamily, size: model.fontSize))
                .tracking(model.tracking)
                .foregroundStyle(model.color)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: model.text)
        }
        .fixedSize()
        // Left-align horizontally, THEN fill the box height — the outer
        // maxHeight frame vertically centers the intrinsic-height stack.
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: .infinity)
    }
}

@objc(NumericTextHostView)
public final class NumericTextHostView: UIView {
    private let model = NumericTextModel()
    private var host: UIHostingController<NumericTextRootView>?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        let controller = UIHostingController(rootView: NumericTextRootView(model: model))
        controller.view.backgroundColor = .clear
        controller.view.frame = bounds
        addSubview(controller.view)
        host = controller
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // Pin the hosting view to our bounds on every layout — Fabric sets our
    // frame after init (bounds start 0), and autoresizingMask alone left the
    // SwiftUI text mis-centered until a content change forced a re-layout.
    public override func layoutSubviews() {
        super.layoutSubviews()
        host?.view.frame = bounds
    }

    @objc public func update(text: String, fontSize: Double, fontFamily: String,
                             colorHex: String, tracking: Double,
                             label: String, labelFontSize: Double,
                             labelFontFamily: String, labelColorHex: String,
                             textGap: Double) {
        if model.fontSize != fontSize { model.fontSize = fontSize }
        if model.fontFamily != fontFamily { model.fontFamily = fontFamily }
        if model.tracking != tracking { model.tracking = tracking }
        let color = Color(hexString: colorHex) ?? .black
        if model.color != color { model.color = color }
        if model.label != label { model.label = label }
        if model.labelFontSize != labelFontSize { model.labelFontSize = labelFontSize }
        if model.labelFontFamily != labelFontFamily { model.labelFontFamily = labelFontFamily }
        let lColor = Color(hexString: labelColorHex) ?? .gray
        if model.labelColor != lColor { model.labelColor = lColor }
        if model.textGap != textGap { model.textGap = textGap }
        // Assign text LAST and only on real change — SwiftUI animates the
        // numericText transition off this published mutation.
        if model.text != text { model.text = text }
        // Force a layout pass once the props land: Fabric sets real bounds
        // AFTER init, and the SwiftUI stack committed against the 0-frame
        // never re-centered until a later relayout.
        DispatchQueue.main.async { [weak self] in
            self?.setNeedsLayout()
            self?.layoutIfNeeded()
        }
    }
}

private extension Color {
    /// #RRGGBB → Color.
    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}
