import SwiftUI

// Wrapper-agnostic config for the glass tab bar. No Expo imports —
// this file ports to a Fabric wrapper unchanged.
//
// v2: material is layered — plain .regular glass at the bottom, a "milk"
// white layer above it, content (icons/highlight) on top, OUTSIDE the glass
// view so Liquid Glass vibrancy can't shift its colors. Theme colors come
// from the Numo palette library (OKLCH-Themes).
struct GlassTabBarConfig: Equatable {
  // Material
  /// Opacity of the white tint blended INTO the glass material. 0 = raw glass.
  /// Kept in-material (Glass.tint) so edges, shimmer and the morph stay alive.
  var milkOpacity: Double = 0.55

  // Theme (resolved on the JS side from the THEMES map)
  var accentHex: String = "#F65D00"          // vibrant: active icon, plus button
  var lightHex: String = "#FFF2ED"           // light: active highlight fill
  var midHex: String = "#888A8E"             // mid: inactive icons

  // Active-tab highlight rendering. Figma uses mix-blend-multiply so the
  // highlight lets the glass/background light through instead of sitting flat.
  var highlightBlend: String = "multiply"    // "multiply" | "normal"
  var highlightOpacity: Double = 1.0

  // Appearance (pinned via overrideUserInterfaceStyle on the hosting UIView)
  var appearance: String = "light"           // "light" | "dark"

  // Coalescence — merge distance between neighbouring glass shapes.
  // The pill↔bubble morph itself is ID-matched and works at any value.
  var containerSpacing: Double = 0

  // Motion
  var springDuration: Double = 0.44          // perceptual seconds
  var springBounce: Double = 0.22

  // Layout (pt, frozen to Figma values — no UI controls)
  var pillWidth: Double = 80
  var pillHeight: Double = 62
  var innerPadding: Double = 4
  var gap: Double = 16
  var hPadding: Double = 24
  var subTabSpacing: Double = 0
  var iconSize: Double = 32
  var plusIconSize: Double = 28
}

extension GlassTabBarConfig {
  var accent: Color { Color(hexString: accentHex) ?? .orange }
  var light: Color { Color(hexString: lightHex) ?? .orange.opacity(0.1) }
  var mid: Color { Color(hexString: midHex) ?? .gray }

  var spring: Animation { .spring(duration: springDuration, bounce: springBounce) }

  var interfaceStyle: UIUserInterfaceStyle {
    appearance == "dark" ? .dark : .light
  }

  /// Milk layer color: white in light appearance, near-black in dark so the
  /// "milky" idea translates instead of blinding.
  var milkColor: Color {
    appearance == "dark" ? (Color(hexString: "#1B1D21") ?? .black) : .white
  }
}

extension Color {
  /// Parses "#RGB", "#RRGGBB" or "#RRGGBBAA". Returns nil for empty/invalid strings.
  init?(hexString: String) {
    var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !hex.isEmpty else { return nil }
    if hex.hasPrefix("#") { hex.removeFirst() }
    if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
    guard hex.count == 6 || hex.count == 8, let value = UInt64(hex, radix: 16) else { return nil }
    let r, g, b, a: Double
    if hex.count == 8 {
      r = Double((value >> 24) & 0xFF) / 255
      g = Double((value >> 16) & 0xFF) / 255
      b = Double((value >> 8) & 0xFF) / 255
      a = Double(value & 0xFF) / 255
    } else {
      r = Double((value >> 16) & 0xFF) / 255
      g = Double((value >> 8) & 0xFF) / 255
      b = Double(value & 0xFF) / 255
      a = 1
    }
    self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
  }
}
