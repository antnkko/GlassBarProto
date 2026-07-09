import SwiftUI
import UIKit

// Our own progressive edge blur — replaces the system UIScrollEdgeEffect
// stack, whose blur band follows the safe area and proved uncontrollable
// from an RN layout. A Material fill masked by an eased gradient is the
// standard public-API progressive blur: full blur at the screen edge fading
// to nothing toward the content. Renders on the simulator too.
struct GlassEdgeBlurView: View {
  /// "top" | "bottom" — which edge the blur is anchored to.
  let edge: String
  /// "light" | "dark" — pins the material appearance (same mechanic as the bar).
  let appearance: String

  var body: some View {
    Rectangle()
      .fill(.ultraThinMaterial)
      .mask(maskGradient)
      .id("scheme-\(appearance)")
      .background(InterfaceStylePinner(style: appearance == "dark" ? .dark : .light))
      .allowsHitTesting(false)
      .ignoresSafeArea()
  }

  // Eased fade: solid at the edge, gone at the content side. The extra
  // mid-stops read as "progressive" instead of a linear wipe.
  private var maskGradient: LinearGradient {
    let stops: [Gradient.Stop] = [
      .init(color: .black, location: 0.0),
      .init(color: .black, location: 0.35),
      .init(color: .black.opacity(0.85), location: 0.55),
      .init(color: .black.opacity(0.55), location: 0.72),
      .init(color: .black.opacity(0.25), location: 0.87),
      .init(color: .clear, location: 1.0),
    ]
    return LinearGradient(
      gradient: Gradient(stops: stops),
      startPoint: edge == "bottom" ? .bottom : .top,
      endPoint: edge == "bottom" ? .top : .bottom
    )
  }
}
