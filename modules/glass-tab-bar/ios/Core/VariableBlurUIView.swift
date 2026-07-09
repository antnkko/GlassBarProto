import UIKit

// The real thing: Apple's system scroll edge effect is a private
// CAFilter("variableBlur") on a backdrop layer — the BLUR RADIUS varies
// along the strip (mask alpha ∝ radius), content stays fully opaque.
// Extracted from the iOS 26.3 runtime: the pocket masks its blur with a
// 24pt gaussian falloff from the bar edge; the chrome material blurs at
// 22.5pt. This view replicates that with the community-proven
// UIVisualEffectView + private-filter technique (jtrivedi/aheze pattern).
//
// Private API — fine for this prototype, NOT App Store material as-is.
// Every private call is guarded; if the filter can't be built the view
// silently stays a plain regular blur.
final class VariableBlurUIView: UIVisualEffectView {
  private var edge = "top"
  private var fadeStart: Double = 0.3
  private var curve: Double = 1.0
  private var intensity: Double = 1.0
  /// Max blur radius at the solid end of the mask (pt). platformChrome uses 22.5.
  private let maxRadius: Double = 22.5

  init() {
    super.init(effect: UIBlurEffect(style: .regular))
    isUserInteractionEnabled = false
    applyFilter()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  func update(edge: String, fadeStart: Double, curve: Double, intensity: Double) {
    guard edge != self.edge || fadeStart != self.fadeStart || curve != self.curve
      || intensity != self.intensity
    else { return }
    self.edge = edge
    self.fadeStart = fadeStart
    self.curve = curve
    self.intensity = intensity
    applyFilter()
  }

  // UIVisualEffectView rebuilds its subview stack on window changes —
  // reapply the filter each time we land in a window.
  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window != nil {
      applyFilter()
    }
  }

  private func applyFilter() {
    guard
      let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
      let filter = filterClass
        .perform(NSSelectorFromString("filterWithType:"), with: "variableBlur")?
        .takeUnretainedValue() as? NSObject,
      let mask = makeMaskImage()
    else { return }

    filter.setValue(maxRadius, forKey: "inputRadius")
    filter.setValue(mask, forKey: "inputMaskImage")
    filter.setValue(true, forKey: "inputNormalizeEdges")

    // The blur lives on the backdrop subview's layer; find it by class name
    // instead of trusting subview order.
    let backdrop = subviews.first {
      String(describing: type(of: $0)).contains("Backdrop")
    } ?? subviews.first
    backdrop?.layer.filters = [filter]

    // Everything above the backdrop is tint/dimming chrome — the system
    // edge effect has none of that (its dimming default is 0.01).
    for subview in subviews where subview !== backdrop {
      subview.alpha = 0
    }
  }

  // 1×128 ramp where the ALPHA channel drives the local blur radius (the
  // runtime's own systemVariableBlurMask is an alpha ramp). Solid `intensity`
  // until fadeStart, then intensity·(1-t)^curve — the same model the panel
  // sliders already control, applied to radius now.
  private func makeMaskImage() -> CGImage? {
    let height = 128
    guard
      let context = CGContext(
        data: nil,
        width: 1,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return nil }

    let start = min(max(fadeStart, 0), 0.95)
    let gamma = max(curve, 0.1)
    let peak = min(max(intensity, 0), 1)

    for row in 0..<height {
      let position = Double(row) / Double(height - 1)
      // t = 0 at the anchored screen edge.
      let t = edge == "bottom" ? 1 - position : position
      let alpha: Double
      if t <= start {
        alpha = peak
      } else {
        let progress = (t - start) / max(1 - start, 0.0001)
        alpha = peak * pow(1 - progress, gamma)
      }
      context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: CGFloat(alpha)))
      // CG origin is bottom-left, our t axis is top-down — flip the row.
      context.fill(CGRect(x: 0, y: height - 1 - row, width: 1, height: 1))
    }

    return context.makeImage()
  }
}
