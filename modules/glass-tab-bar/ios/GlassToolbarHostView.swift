import SwiftUI
import UIKit

// Fabric bridge for the glass toolbar — same shape as GlassTabBarHostView
// (shared GlassBridgeState lives there).

private struct GlassToolbarRoot: View {
  @ObservedObject var state: GlassBridgeState

  var body: some View {
    GlassToolbarView(
      config: state.config,
      option: state.option,
      onPress: { [weak state] element, seq in state?.onToolbarPress?(element, seq) }
    )
  }
}

@objc(GlassToolbarHostView)
public final class GlassToolbarHostView: UIView {
  private let state = GlassBridgeState()
  private let host: UIHostingController<GlassToolbarRoot>
  private var edgeExtension: Double = 0

  @objc public var onToolbarPress: ((NSString, NSInteger) -> Void)?

  public override init(frame: CGRect) {
    host = UIHostingController(rootView: GlassToolbarRoot(state: state))
    super.init(frame: frame)

    host.view.backgroundColor = .clear
    host.safeAreaRegions = []
    host.view.frame = bounds
    host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(host.view)

    state.onToolbarPress = { [weak self] element, seq in self?.onToolbarPress?(element as NSString, seq) }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  @objc public func update(option: Int, config: [String: Any]) {
    let next = GlassTabBarConfig(bridge: config)
    if state.config != next { state.config = next }
    if state.option != option { state.option = option }
  }

  // MARK: - Safe-area extension (the real blur-region knob)

  // The scroll edge effect's blur band follows the scroll view's SAFE AREA,
  // not its content inset. Growing the root view controller's
  // additionalSafeAreaInsets is the public way native bars extend the blur
  // region — and contentInsetAdjustmentBehavior=automatic picks it up on the
  // RN scroll view, content offset compensation included.
  @objc public func setEdgeExtension(_ value: Double) {
    guard value != edgeExtension else { return }
    edgeExtension = value
    applyEdgeExtension(value)
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    // Unmounting the toolbar (option 0 / screen teardown) hands the safe
    // area back; mounting applies the pending value.
    applyEdgeExtension(window == nil ? 0 : edgeExtension)
  }

  private func applyEdgeExtension(_ value: Double) {
    guard let vc = rootViewController() else { return }
    let inset = CGFloat(value)
    if vc.additionalSafeAreaInsets.top != inset {
      vc.additionalSafeAreaInsets.top = inset
    }
  }

  private func rootViewController() -> UIViewController? {
    // Walk the responder chain to the outermost view controller (our own
    // UIHostingController is not a child VC, so the chain leads straight to
    // the RN root controller). Fall back to the window's root.
    var responder: UIResponder? = next
    var found: UIViewController?
    while let current = responder {
      if let vc = current as? UIViewController {
        found = vc
      }
      responder = current.next
    }
    return found ?? window?.rootViewController
  }
}
