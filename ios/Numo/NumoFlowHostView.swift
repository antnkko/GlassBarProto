import SwiftUI
import UIKit

// Live RN props for the mounted flow (Stage 41): unlike mode/seq (one immutable
// mode per mount), these mutate the RUNNING SwiftUI tree — RN owns the
// bottom-bar cluster and mirrors its When-picker state into the native screen
// (header swap, input backdrop, tap-catcher). Plain @Published writes; the
// consumers apply their own animations where the values are read.
final class NumoFlowPropsBridge: ObservableObject {
    @Published var rnBottomBar = false
    @Published var whenPickerOpen = false
    @Published var routinePickerOpen = false
}

// Fabric host for the braindump overlay. Differences from the glass hosts:
// - The hosting view stays TRANSPARENT (iOS 26 defaults it to systemBackground)
//   so the RN screen shows through during the slide-up rise.
// - safeAreaRegions is left at its default: the donor screens need real safe
//   areas and the hosting view's built-in keyboard avoidance.
// - The hosting controller is added as a child of the root view controller —
//   without containment, onAppear/first-responder behavior is flaky when a
//   UIHostingController's view lives inside an RN hierarchy.
@objc(NumoFlowHostView)
public final class NumoFlowHostView: UIView {
    private var host: UIHostingController<NumoFlowRoot>?

    @objc public var onFlowEvent: ((NSString) -> Void)?

    private var mode = ""
    private var mounted = false
    // The braindump chrome's glass shadow, mirrored from the dev panel. Only
    // ever changes while the overlay is CLOSED (the open overlay swallows all
    // touches, so the panel is unreachable), so the fresh values are read at
    // the next mount — no live re-config needed.
    private var shadowOpacity = 0.35
    private var shadowRadius = 0.35
    // Live props for the mounted tree (RN-owned bottom bar) — written on every
    // updateProps, consumed reactively by the SwiftUI side.
    private let bridge = NumoFlowPropsBridge()

    @objc public func update(mode: String, seq: Int, shadowOpacity: Double, shadowRadius: Double,
                             rnBottomBar: Bool, whenPickerOpen: Bool, routinePickerOpen: Bool) {
        self.shadowOpacity = shadowOpacity
        self.shadowRadius = shadowRadius
        if bridge.rnBottomBar != rnBottomBar { bridge.rnBottomBar = rnBottomBar }
        if bridge.whenPickerOpen != whenPickerOpen { bridge.whenPickerOpen = whenPickerOpen }
        if bridge.routinePickerOpen != routinePickerOpen { bridge.routinePickerOpen = routinePickerOpen }
        guard !mounted || mode != self.mode else { return }
        self.mode = mode
        remount()
    }

    private func remount() {
        tearDownHost()
        guard !mode.isEmpty, mode != "none" else { return }
        let root = NumoFlowRoot(
            mode: mode, shadowOpacity: shadowOpacity, shadowRadius: shadowRadius,
            bridge: bridge,
            onEvent: { [weak self] type in self?.onFlowEvent?(type as NSString) },
            onClosed: { [weak self] in self?.onFlowEvent?("closed") }
        )
        let controller = UIHostingController(rootView: root)
        controller.view.backgroundColor = .clear
        controller.view.frame = bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host = controller
        mounted = true
        attachIfPossible()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            attachIfPossible()
        } else {
            endEditing(true)
        }
    }

    private func attachIfPossible() {
        guard let controller = host, controller.view.superview !== self || controller.parent == nil,
              let window else { return }
        guard let rootVC = window.rootViewController else { return }
        if controller.parent == nil {
            rootVC.addChild(controller)
        }
        if controller.view.superview !== self {
            controller.view.frame = bounds
            addSubview(controller.view)
        }
        controller.didMove(toParent: rootVC)
    }

    @objc public func tearDown() {
        endEditing(true)
        tearDownHost()
    }

    private func tearDownHost() {
        if let controller = host {
            controller.willMove(toParent: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParent()
        }
        host = nil
        mounted = false
    }
}
