import SwiftUI
import UIKit

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

    @objc public func update(mode: String, seq: Int) {
        guard !mounted || mode != self.mode else { return }
        self.mode = mode
        remount()
    }

    private func remount() {
        tearDownHost()
        guard !mode.isEmpty, mode != "none" else { return }
        let root = NumoFlowRoot(mode: mode) { [weak self] in
            self?.onFlowEvent?("closed")
        }
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
