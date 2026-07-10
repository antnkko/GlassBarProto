import UIKit

// Fabric bridge for the progressive blur stack — pure UIKit, no hosting.

@objc(GlassEdgeBlurHostView)
public final class GlassEdgeBlurHostView: UIView {
  private let stack = ProgressiveBlurStackView(frame: .zero)

  public override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    stack.frame = bounds
    stack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(stack)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  @objc public func update(edge: String, maxRadius: Double, smoothness: Double) {
    stack.update(edge: edge, maxRadius: maxRadius, smoothness: smoothness)
  }
}
