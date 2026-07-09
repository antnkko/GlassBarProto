import SwiftUI
import UIKit

// Fabric bridge for the progressive edge blur strip. No events, two props.

final class GlassEdgeState: ObservableObject {
  @Published var edge = "top"
  @Published var appearance = "light"
}

private struct GlassEdgeRoot: View {
  @ObservedObject var state: GlassEdgeState

  var body: some View {
    GlassEdgeBlurView(edge: state.edge, appearance: state.appearance)
  }
}

@objc(GlassEdgeHostView)
public final class GlassEdgeHostView: UIView {
  private let state = GlassEdgeState()
  private let host: UIHostingController<GlassEdgeRoot>

  public override init(frame: CGRect) {
    host = UIHostingController(rootView: GlassEdgeRoot(state: state))
    super.init(frame: frame)

    host.view.backgroundColor = .clear
    host.safeAreaRegions = []
    host.view.frame = bounds
    host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    isUserInteractionEnabled = false
    addSubview(host.view)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  @objc public func update(edge: String, appearance: String) {
    if state.edge != edge { state.edge = edge }
    if state.appearance != appearance { state.appearance = appearance }
  }
}
