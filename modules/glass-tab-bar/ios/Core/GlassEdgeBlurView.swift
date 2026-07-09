import SwiftUI
import UIKit

// Our own progressive edge blur — replaces the system UIScrollEdgeEffect
// stack, whose blur band follows the safe area and proved uncontrollable
// from an RN layout. A Material fill masked by an eased gradient is the
// standard public-API progressive blur: full blur at the screen edge fading
// to nothing toward the content. Renders on the simulator too.
//
// Fully tunable from the dev panel: material thickness, where the fade
// starts, the falloff gamma and a global intensity multiplier.
struct GlassEdgeBlurView: View {
  /// "top" | "bottom" — which edge the blur is anchored to.
  let edge: String
  /// "light" | "dark" — pins the material appearance (same mechanic as the bar).
  let appearance: String
  /// "ultraThin" | "thin" | "regular" | "thick" — blur strength.
  var material: String = "ultraThin"
  /// 0...0.8 — portion of the strip that stays fully blurred before fading.
  var fadeStart: Double = 0.35
  /// Falloff gamma: 1 = linear fade, higher = steeper drop toward content.
  var curve: Double = 1.4
  /// 0...1 — global multiplier on the whole strip.
  var intensity: Double = 1.0

  var body: some View {
    Group {
      if material == "apple" {
        // The real system mechanic: private variableBlur, radius ramps along
        // the strip while content stays opaque. No frost wash.
        VariableBlurRepresentable(
          edge: edge,
          fadeStart: fadeStart,
          curve: curve,
          intensity: intensity
        )
      } else {
        // Legal fallback: uniform Material faded by an opacity mask.
        Rectangle()
          .fill(resolvedMaterial)
          .mask(maskGradient)
      }
    }
    .id("scheme-\(appearance)")
    .background(InterfaceStylePinner(style: appearance == "dark" ? .dark : .light))
    .allowsHitTesting(false)
    .ignoresSafeArea()
  }

  fileprivate struct VariableBlurRepresentable: UIViewRepresentable {
    let edge: String
    let fadeStart: Double
    let curve: Double
    let intensity: Double

    func makeUIView(context: Context) -> VariableBlurUIView {
      let view = VariableBlurUIView()
      view.update(edge: edge, fadeStart: fadeStart, curve: curve, intensity: intensity)
      return view
    }

    func updateUIView(_ view: VariableBlurUIView, context: Context) {
      view.update(edge: edge, fadeStart: fadeStart, curve: curve, intensity: intensity)
    }
  }

  private var resolvedMaterial: Material {
    switch material {
    case "thin": return .thinMaterial
    case "regular": return .regularMaterial
    case "thick": return .thickMaterial
    default: return .ultraThinMaterial
    }
  }

  // Gamma-eased fade sampled into gradient stops: solid until fadeStart,
  // then opacity = (1 - progress)^curve, everything scaled by intensity.
  private var maskGradient: LinearGradient {
    let start = min(max(fadeStart, 0), 0.85)
    let gamma = max(curve, 0.1)
    let peak = min(max(intensity, 0), 1)

    var stops: [Gradient.Stop] = [.init(color: .black.opacity(peak), location: 0)]
    if start > 0 {
      stops.append(.init(color: .black.opacity(peak), location: start))
    }
    let samples = 8
    for i in 1...samples {
      let progress = Double(i) / Double(samples)
      let opacity = peak * pow(1 - progress, gamma)
      let location = start + (1 - start) * progress
      stops.append(.init(color: .black.opacity(opacity), location: location))
    }

    return LinearGradient(
      gradient: Gradient(stops: stops),
      startPoint: edge == "bottom" ? .bottom : .top,
      endPoint: edge == "bottom" ? .top : .bottom
    )
  }
}
