import SwiftUI
import UIKit

/// Hosts a SwiftUI `Text` with the real `.contentTransition(.numericText())`
/// — Apple's per-glyph roll + blur when the string changes. The RN side just
/// pushes the string (and static font/color) via @Published; SwiftUI runs the
/// transition on the donor spring (response 0.4 / dampingFraction 0.6, the
/// DumpedScreen title's numericText).
final class NumericTextModel: ObservableObject {
    @Published var text = ""
    @Published var fontSize: CGFloat = 17
    @Published var fontFamily = "Obviously-Semibold"
    @Published var color = Color.black
    @Published var tracking: CGFloat = 0
}

private struct NumericTextRootView: View {
    @ObservedObject var model: NumericTextModel

    var body: some View {
        Text(model.text)
            .font(.custom(model.fontFamily, size: model.fontSize))
            .tracking(model.tracking)
            .foregroundStyle(model.color)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: model.text)
            // Vertically centered in the RN-given box (leading = centerY +
            // leftX), so the caller sizes the line box and the glyph sits in
            // the middle — matching a normal text line's position.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(controller.view)
        host = controller
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc public func update(text: String, fontSize: Double, fontFamily: String,
                             colorHex: String, tracking: Double) {
        if model.fontSize != fontSize { model.fontSize = fontSize }
        if model.fontFamily != fontFamily { model.fontFamily = fontFamily }
        if model.tracking != tracking { model.tracking = tracking }
        let color = Color(hexString: colorHex) ?? .black
        if model.color != color { model.color = color }
        // Assign text LAST and only on real change — SwiftUI animates the
        // numericText transition off this published mutation.
        if model.text != text { model.text = text }
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
