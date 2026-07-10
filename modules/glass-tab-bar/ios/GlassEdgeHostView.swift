import SwiftUI
import UIKit

// Fabric bridge for the progressive edge blur strip. No events.

final class GlassEdgeState: ObservableObject {
  @Published var edge = "top"
  @Published var appearance = "light"
  @Published var material = "ultraThin"
  @Published var fadeStart = 0.35
  @Published var curve = 1.4
  @Published var intensity = 1.0
  @Published var blurRadius = 18.0
  @Published var blurCurve = 2.0
}

private struct GlassEdgeRoot: View {
  @ObservedObject var state: GlassEdgeState

  var body: some View {
    GlassEdgeBlurView(
      edge: state.edge,
      appearance: state.appearance,
      material: state.material,
      fadeStart: state.fadeStart,
      curve: state.curve,
      intensity: state.intensity,
      blurRadius: state.blurRadius,
      blurCurve: state.blurCurve
    )
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

  @objc public func update(
    edge: String,
    appearance: String,
    material: String,
    fadeStart: Double,
    curve: Double,
    intensity: Double,
    blurRadius: Double,
    blurCurve: Double
  ) {
    if state.edge != edge { state.edge = edge }
    if state.appearance != appearance { state.appearance = appearance }
    if state.material != material { state.material = material }
    if state.fadeStart != fadeStart { state.fadeStart = fadeStart }
    if state.curve != curve { state.curve = curve }
    if state.intensity != intensity { state.intensity = intensity }
    if state.blurRadius != blurRadius { state.blurRadius = blurRadius }
    if state.blurCurve != blurCurve { state.blurCurve = blurCurve }
  }
}
