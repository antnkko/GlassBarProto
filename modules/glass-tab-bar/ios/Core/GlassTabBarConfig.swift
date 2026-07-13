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

  /// Design stroke: "off" | "outer" (ring). Frozen to outer by the JS side.
  var strokeMode: String = "outer"

  /// Liquid Glass variant: "regular" | "clear".
  var glassVariant: String = "regular"
  /// Whether the glass reacts to touch (press stretch / shimmer).
  var glassInteractive: Bool = true
  /// Drop shadow: "none" | "design" (caster ring on the white elements).
  /// Frozen to design by the JS side.
  var shadowMode: String = "design"
  /// Absolute 0–1 knobs (field names are historical bridge names): opacity is
  /// the shadow alpha, radius maps 0–1 → 0–40pt. Group keeps the design's
  /// proportions relative to neutral (×0.67 / ×0.8); accent has no shadow.
  var shadowOpacityScale: Double = 0.35
  var shadowRadiusScale: Double = 0.35

  /// Extra frost: an opaque tint layer inside the glass, under the content.
  /// Mattes the material AND covers the rim specular glints (0 = none).
  var frost: Double = 0
  /// Outer stroke color choice: "white" | "black" | "accent" | "gray".
  var strokeColorChoice: String = "gray"
  /// Outer stroke opacity.
  var strokeOpacity: Double = 0.13
  /// Accent ring (plus, CTA) opacity — panel-controlled.
  var accentStrokeOpacity: Double = 0.65
  /// White inner glow opacity in accent buttons — panel-controlled, 0 = off.
  var accentGlowOpacity: Double = 0.5
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

  /// The neutral pill material assembled from the panel's Liquid Glass
  /// controls: variant, milk tint and interactivity.
  var pillGlass: Glass {
    var glass = baseGlass
    if milkOpacity > 0.01 {
      glass = glass.tint(milkColor.opacity(milkOpacity))
    }
    return glassInteractive ? glass.interactive() : glass
  }

  /// Accent-filled pill material (plus button, CTA): same variant and
  /// interactivity, accent tint instead of milk.
  var accentGlass: Glass {
    let glass = baseGlass.tint(accent)
    return glassInteractive ? glass.interactive() : glass
  }

  /// Accent button fill with the design's white inner glow (Figma 387:2498:
  /// inset 0 0 8 4 white@0.5 — the spread is approximated by stacking a
  /// tight and a wide inner shadow). Lives IN the glass content, so the
  /// press stretch and the morph carry it — no feedback fade needed.
  /// Glow opacity is panel-controlled; 0 turns the glow off entirely.
  var accentFill: AnyShapeStyle {
    guard accentGlowOpacity > 0.01 else { return AnyShapeStyle(accent) }
    return AnyShapeStyle(
      accent
        .shadow(.inner(color: .white.opacity(accentGlowOpacity), radius: 4))
        .shadow(.inner(color: .white.opacity(accentGlowOpacity), radius: 10))
    )
  }

  private var baseGlass: Glass {
    glassVariant == "clear" ? .clear : .regular
  }
}

// MARK: - Stroke + shadow decoration (design experiment, panel-switchable)

/// Which stroke/shadow recipe a glass element uses.
enum GlassDecorKind {
  /// White pills: ring rgba(193,195,198,0.13), shadow 0 0 20 rgba(193,195,198,0.3).
  case neutral
  /// Accent-filled pills (plus, CTA): accent@0.7 stroke, shadow 0 0 16 black@0.2.
  case accent
  /// The toolbar button group: #F1F1F1 stroke, shadow 0 0 16 black@0.2.
  case group
}

extension View {
  /// Applies the outer stroke AFTER the glass so the material, press stretch,
  /// shimmer and morphs stay untouched. Off = nothing.
  @ViewBuilder
  func glassDecoration<S: InsettableShape>(
    _ shape: S, kind: GlassDecorKind, config: GlassTabBarConfig, visible: Bool = true
  ) -> some View {
    if config.strokeMode == "outer" {
      // The stroke sits as an outer overlay (visible at rest). It fades out
      // smoothly during any feedback — press stretch, tap, morph — and back
      // in only once the button fully settles, so it never reads as a
      // separate static layer over the moving glass. Accent buttons take the
      // design's own rim (accent @0.75, Figma 387:2498) instead of the
      // panel-controlled neutral color.
      // The fade is driven by withAnimation at the state change. The accent
      // ring is high-contrast, so it additionally takes its own directional
      // animation: a longer, softer fade-in (0.45s) while keeping the hide
      // fast (0.12s) so it never lingers over the stretching glass. Safe for
      // the freshly inserted plus: the morph clear arrives by timer AFTER
      // insertion, so the value changes on a live view.
      let color = kind == .accent
        ? config.accent.opacity(config.accentStrokeOpacity)
        : config.outerStrokeColor
      let ring = shape.inset(by: -1).stroke(color, lineWidth: 2)
        .opacity(visible ? 1 : 0)
      if kind == .accent {
        self.overlay(
          ring.animation(
            visible ? .easeInOut(duration: 0.45) : .easeInOut(duration: 0.12),
            value: visible)
        )
      } else {
        self.overlay(ring)
      }
    } else {
      self
    }
  }

  /// Frost layer: fills the glass shape with an opaque tint UNDER the content
  /// (icons stay crisp above it) — mattes the glass and covers rim glints.
  @ViewBuilder
  func frostFill<S: Shape>(_ shape: S, config: GlassTabBarConfig) -> some View {
    if config.frost > 0.01 {
      shape.fill(config.milkColor.opacity(config.frost))
    }
  }

  /// Design drop shadow, panel-switchable. .shadow directly on the glass view
  /// is dead on device: real Liquid Glass is a backdrop effect with almost no
  /// alpha of its own, so there is nothing to cast from (the simulator's
  /// opaque wash DOES have alpha, which made it look fine there). Instead an
  /// explicit caster shape draws the shadow from BEHIND the glass, with its
  /// own body punched out of the mask so only the outer ring remains — a flat
  /// soft gradient in the backdrop, safe for the glass sampling.
  /// Base values from the Figma mock: neutral 0 0 20 rgba(193,195,198,0.3);
  /// accent/group 0 0 16 black@0.2 — scaled by the panel's multipliers.
  @ViewBuilder
  func glassShadow<S: InsettableShape>(
    _ shape: S, kind: GlassDecorKind, config: GlassTabBarConfig, visible: Bool = true
  ) -> some View {
    if config.shadowMode == "design" {
      // Same feedback rule as the stroke: the ring is anchored to the frame,
      // so during the interactive stretch/morph it would lag the glass and
      // read as a leftover. It fades out on press/morph and returns only
      // after the element settles; the fade itself is driven by withAnimation
      // at the state change (see glassDecoration).
      self.background(
        GlassShadowSource(shape: shape, kind: kind, config: config)
          .opacity(visible ? 1 : 0)
      )
    } else {
      self
    }
  }
}

/// Shadow without a visible source: an opaque caster fills the glass shape,
/// its drop shadow paints the ring, then the mask keeps only the pixels
/// OUTSIDE the shape — the caster disappears, the shadow stays.
private struct GlassShadowSource<S: InsettableShape>: View {
  let shape: S
  let kind: GlassDecorKind
  let config: GlassTabBarConfig

  var body: some View {
    let neutral = kind == .neutral
    // Panel knobs are absolute 0–1: radius 1.0 = 40pt, opacity is the alpha.
    // Accent/group keep the design's proportions vs neutral (16/20, 0.2/0.3),
    // so the defaults 0.5/0.3 reproduce the mock exactly for every kind.
    let radius = config.shadowRadiusScale * 40 * (neutral ? 1.0 : 0.8)
    let color = (neutral ? (Color(hexString: "#C1C3C6") ?? .gray) : Color.black)
      .opacity(min(1, config.shadowOpacityScale * (neutral ? 1.0 : 0.67)))
    shape
      .fill(Color.black)
      .shadow(color: color, radius: radius)
      .mask {
        Rectangle()
          .padding(-(radius * 3 + 20))
          .overlay(shape.fill(Color.black).blendMode(.destinationOut))
          .compositingGroup()
      }
  }
}

extension GlassTabBarConfig {
  /// The single, panel-controlled outer stroke color (choice + opacity),
  /// applied uniformly to every element in outer mode.
  var outerStrokeColor: Color {
    let base: Color
    switch strokeColorChoice {
    case "white": base = .white
    case "black": base = .black
    case "accent": base = accent
    default: base = Color(hexString: "#C1C3C6") ?? .gray
    }
    return base.opacity(strokeOpacity)
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
