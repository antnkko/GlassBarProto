import UIKit

// Seamless progressive blur, built the way implementations that survive the
// eyeball test build it (Glur / kennethnym): a STACK of fixed-radius
// gaussian blurs, each masked by its own gradient band, handing off in
// log-radius space. A fixed gaussian has no mip quantization (the visible
// "line where blur starts" of a single variableBlur), and the entry into the
// zone is the smallest-radius layer fading to zero alpha — a ~1.5pt blur at
// low alpha is below perception, so the onset is structurally invisible.
//
// The master intensity profile is the SAME design curve the RN scrim uses
// (Figma 320:2512, 16 points), raised to the shared `smoothness` power, so
// tint and blur move together.
//
// Private CAFilter API — prototype only; guarded, degrades to nothing.
final class ProgressiveBlurStackView: UIView {
  // Normalized design curve: (position, intensity), position 0 = transparent
  // end, 1 = dense screen edge. Values are Figma alphas / 0.9.
  private static let designCurve: [(Double, Double)] = [
    (0, 0), (0.1179, 0.0733), (0.21384, 0.1533), (0.2912, 0.2389),
    (0.35336, 0.3256), (0.4037, 0.4144), (0.4456, 0.5033), (0.48243, 0.59),
    (0.51757, 0.6722), (0.5544, 0.7489), (0.5963, 0.8189), (0.64664, 0.8789),
    (0.7088, 0.93), (0.78616, 0.9678), (0.8821, 0.9911), (1, 1),
  ]

  /// Radius fractions per layer; the largest is `maxRadius`.
  private static let radiusSteps: [Double] = [1.0 / 16, 1.0 / 8, 1.0 / 4, 1.0 / 2, 1.0]
  private static let maskSamples = 32

  private var layersBuilt = false
  private var blurViews: [UIVisualEffectView] = []
  private var maskLayers: [CAGradientLayer] = []

  private var edge = "top"
  private var maxRadius: Double = 24
  private var smoothness: Double = 1.6

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    buildLayers()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  func update(edge: String, maxRadius: Double, smoothness: Double) {
    guard edge != self.edge || maxRadius != self.maxRadius || smoothness != self.smoothness
    else { return }
    self.edge = edge
    self.maxRadius = maxRadius
    self.smoothness = smoothness
    applyRadii()
    refreshMasks()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    for view in blurViews {
      view.frame = bounds
    }
    refreshMasks()
  }

  // MARK: - Stack construction

  private func buildLayers() {
    guard !layersBuilt, NSClassFromString("CAFilter") != nil else { return }
    layersBuilt = true

    for _ in Self.radiusSteps {
      let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
      effectView.isUserInteractionEnabled = false
      effectView.frame = bounds
      addSubview(effectView)
      blurViews.append(effectView)

      let mask = CAGradientLayer()
      mask.startPoint = CGPoint(x: 0.5, y: 0)
      mask.endPoint = CGPoint(x: 0.5, y: 1)
      effectView.layer.mask = mask
      maskLayers.append(mask)
    }
    applyRadii()
  }

  private func applyRadii() {
    guard let filterClass = NSClassFromString("CAFilter") as? NSObject.Type else { return }
    for (index, effectView) in blurViews.enumerated() {
      let radius = maxRadius * Self.radiusSteps[index]
      guard
        let filter = filterClass
          .perform(NSSelectorFromString("filterWithType:"), with: "gaussianBlur")?
          .takeUnretainedValue() as? NSObject
      else { continue }
      filter.setValue(radius, forKey: "inputRadius")
      filter.setValue(true, forKey: "inputNormalizeEdges")

      let backdrop = effectView.subviews.first {
        String(describing: type(of: $0)).contains("Backdrop")
      } ?? effectView.subviews.first
      backdrop?.layer.filters = [filter]

      // Tint/dimming chrome off — this stack is pure blur; the scrim above
      // provides the wash.
      for subview in effectView.subviews where subview !== backdrop {
        subview.alpha = 0
      }
    }
  }

  // MARK: - Masks (the seamless part)

  // Intensity profile along the strip: u = 0 at the screen edge.
  private func intensity(atUnit u: Double) -> Double {
    let p = max(0, min(1, 1 - u)) // design curve's axis: 1 = dense edge
    let base = Self.sampleCurve(p)
    return pow(base, max(1, smoothness))
  }

  private static func sampleCurve(_ p: Double) -> Double {
    var previous = designCurve[0]
    for point in designCurve.dropFirst() {
      if p <= point.0 {
        let span = point.0 - previous.0
        guard span > 0 else { return point.1 }
        let f = (p - previous.0) / span
        return previous.1 + (point.1 - previous.1) * f
      }
      previous = point
    }
    return 1
  }

  // Triangular partition of unity in log2 radius space: layer i owns blur
  // levels around its own radius, crossfading into neighbours; the smallest
  // layer fades linearly to zero below its radius — the invisible entry.
  private func weight(ofLayer index: Int, blurAt: Double) -> Double {
    let radii = Self.radiusSteps.map { $0 * maxRadius }
    let r = radii[index]
    guard blurAt > 0.0001 else { return 0 }
    if index == 0 && blurAt <= r {
      return blurAt / r
    }
    if index == radii.count - 1 && blurAt >= r {
      return 1
    }
    let distance = abs(log2(blurAt) - log2(r))
    return max(0, 1 - distance)
  }

  private func refreshMasks() {
    guard bounds.height > 0, !maskLayers.isEmpty else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for (index, mask) in maskLayers.enumerated() {
      var colors: [CGColor] = []
      var locations: [NSNumber] = []
      for sample in 0..<Self.maskSamples {
        let position = Double(sample) / Double(Self.maskSamples - 1)
        // position runs top -> bottom in layer space; unit distance from the
        // anchored screen edge depends on which edge we hug.
        let u = edge == "bottom" ? 1 - position : position
        let blur = maxRadius * intensity(atUnit: u)
        let alpha = weight(ofLayer: index, blurAt: blur)
        colors.append(UIColor(white: 0, alpha: CGFloat(alpha)).cgColor)
        locations.append(NSNumber(value: position))
      }
      mask.frame = bounds
      mask.colors = colors
      mask.locations = locations
    }
    CATransaction.commit()
  }
}
