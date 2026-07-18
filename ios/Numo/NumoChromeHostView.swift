import GlassTabBar
import SwiftUI
import UIKit

private typealias R = Metrics.Redesign

/// Hosts the redesigned screen's top chrome as a Fabric leaf (Stage 50) — the
/// header ZStack lifted verbatim from `RedesignedScreen.sheet()`: centered
/// "When" title + the two Liquid Glass clusters (✕ + publicity/tags pill ⇄
/// Clear + ✓) cross-fading on blur+opacity when `pickerOpen` flips, on the
/// exact native springs (`MorphChoreo.placeholderSwap` / easeOut 0.18). The
/// buttons are the same `GlassButton` component the toolbar uses, so material,
/// decor and press feedback stay native; the RN flow (Reanimated) owns only
/// this leaf's container transforms (entrance drop / close crop).
final class NumoChromeModel: ObservableObject {
    @Published var pickerOpen = false
    @Published var pickerTitle = "When"
    @Published var tag: String? = nil
    @Published var glass = GlassTabBarConfig.frozen()
}

private struct NumoChromeRootView: View {
    @ObservedObject var model: NumoChromeModel
    let onPress: (String) -> Void

    /// Peak blur (pt) as the chrome cross-fades ✕/publicity ⇄ Clear·✓.
    private static let headerBlur: CGFloat = 8

    var body: some View {
        ZStack {
            // Centered "When" title — eases in with the picker, leaves FAST.
            Text(model.pickerTitle)
                .font(NumoFont.obviouslyNarrowBold(R.WhenPicker.titleSize))
                .tracking(R.WhenPicker.titleTracking)
                .foregroundStyle(NumoColor.black)
                .opacity(model.pickerOpen ? 1 : 0)
                .blur(radius: model.pickerOpen ? 0 : Self.headerBlur)
                .animation(
                    model.pickerOpen ? MorphChoreo.placeholderSwap : .easeOut(duration: 0.18),
                    value: model.pickerOpen)

            // Both clusters are always laid out in the same slot and swap via
            // blur+opacity (the donor's cross-fade — no matched glass morph).
            ZStack {
                // CLOSED — ✕ + publicity/tags; blurs out in place.
                HStack {
                    closeButton
                    Spacer(minLength: 0)
                    publicityGroup
                }
                .opacity(model.pickerOpen ? 0 : 1)
                .blur(radius: model.pickerOpen ? Self.headerBlur : 0)
                .allowsHitTesting(!model.pickerOpen)

                // OPEN — Clear · ✓; blurs in at its final positions.
                HStack {
                    clearButton
                    Spacer(minLength: 0)
                    confirmButton
                }
                .opacity(model.pickerOpen ? 1 : 0)
                .blur(radius: model.pickerOpen ? 0 : Self.headerBlur)
                .allowsHitTesting(model.pickerOpen)
            }
            .animation(MorphChoreo.placeholderSwap, value: model.pickerOpen)
            .padding(.horizontal, R.WhenPicker.headerPadH)
            .padding(.vertical, R.WhenPicker.headerPadV)
        }
        // Stage 61: the host view is taller than the chrome slot (the glass
        // container's top bound must sit far above the buttons — a nearby
        // bound rendered the material's edge falloff as a dark top stripe).
        // The header itself stays bottom-aligned in the 88pt slot.
        .frame(height: 88)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var closeButton: some View {
        GlassButton(Circle(), config: model.glass,
                    pressEnabled: !model.pickerOpen,
                    interaction: .tap { onPress("close") }) {
            Image("cross")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: R.crossIcon, height: R.crossIcon)
                .foregroundStyle(NumoColor.grayNight)
                .frame(width: R.closeSize, height: R.closeSize)
        }
    }

    private var publicityGroup: some View {
        GlassButton(Capsule(), kind: .group, config: model.glass,
                    pressEnabled: !model.pickerOpen,
                    interaction: .group) {
            PublicityTagsPill(bare: true, tag: model.tag)
        }
    }

    private var clearButton: some View {
        GlassButton(Capsule(), config: model.glass,
                    pressEnabled: model.pickerOpen,
                    interaction: .tap { onPress("clear") }) {
            Text("Clear")
                .font(NumoFont.obviouslySemibold(R.WhenPicker.clearLabel))
                .foregroundStyle(NumoColor.neutralDark)
                .padding(.bottom, R.WhenPicker.clearLabelLift)
                .frame(width: R.WhenPicker.clearWidth, height: R.WhenPicker.clearHeight)
        }
    }

    private var confirmButton: some View {
        GlassButton(Capsule(), kind: .accent, config: model.glass,
                    pressEnabled: model.pickerOpen,
                    interaction: .tap { onPress("confirm") }) {
            Image("picker_checkmark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: R.WhenPicker.checkIcon, height: R.WhenPicker.checkIcon)
                .foregroundStyle(NumoColor.white)
                .frame(width: R.WhenPicker.clearWidth, height: R.WhenPicker.clearHeight)
        }
    }
}

@objc(NumoChromeHostView)
public final class NumoChromeHostView: UIView {
    private let model = NumoChromeModel()
    private var host: UIHostingController<NumoChromeRootView>?

    @objc public var onChromePress: ((String) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        let controller = UIHostingController(
            rootView: NumoChromeRootView(model: model) { [weak self] element in
                self?.onChromePress?(element)
            }
        )
        controller.view.backgroundColor = .clear
        controller.view.frame = bounds
        // Never inherit safe-area/keyboard insets inside an RN-sized box —
        // the braindump keyboard is always up (Stage 45–48 lesson).
        controller.safeAreaRegions = []
        addSubview(controller.view)
        host = controller
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // Pin the hosting view to our bounds on every layout — Fabric sets our
    // frame after init (bounds start 0).
    public override func layoutSubviews() {
        super.layoutSubviews()
        host?.view.frame = bounds
    }

    @objc public func update(pickerOpen: Bool, pickerTitle: String, tag: String,
                             useSafeArea: Bool, shadowOpacity: Double, shadowRadius: Double) {
        // Stage 62 DEBUG: runtime bisect of the dark-stripe suspects.
        let regions: SwiftUI.SafeAreaRegions = useSafeArea ? .all : []
        if host?.safeAreaRegions != regions { host?.safeAreaRegions = regions }
        if model.pickerTitle != pickerTitle { model.pickerTitle = pickerTitle }
        let glass = GlassTabBarConfig.frozen(shadowOpacity: shadowOpacity,
                                             shadowRadius: shadowRadius)
        if model.glass != glass { model.glass = glass }
        let newTag: String? = tag.isEmpty ? nil : tag
        if model.tag != newTag {
            withAnimation(MorphChoreo.placeholderSwap) { model.tag = newTag }
        }
        // Assign LAST and only on real change — the attached `.animation`
        // modifiers run the cluster swap off this published mutation.
        if model.pickerOpen != pickerOpen { model.pickerOpen = pickerOpen }
    }
}
