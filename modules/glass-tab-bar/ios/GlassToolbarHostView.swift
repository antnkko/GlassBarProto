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
}
