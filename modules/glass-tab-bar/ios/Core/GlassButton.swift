import SwiftUI

/// A matched-morph identity for a glass button (glassEffectID + namespace),
/// so a caller can opt a button into a `GlassEffectContainer` morph.
public struct GlassButtonID {
  let id: AnyHashable
  let ns: Namespace.ID
  public init(_ id: some Hashable, in ns: Namespace.ID) {
    self.id = id
    self.ns = ns
  }
}

/// The single source of truth for every Liquid Glass button in the app —
/// the toolbar buttons are the reference, and the braindump chrome (and any
/// future screen) build from this so behaviour and look are identical.
///
/// It owns its own press feedback: the ring + shadow fade out while the glass
/// is dragged/stretched and return after the release settles. The press
/// detector is a `.simultaneousGesture`, which fires alongside the interactive
/// glass's own touch handling — so the decor hides on a drag whether the
/// button is standalone or inside a `GlassEffectContainer` (a plain
/// `.gesture` loses the drag to standalone interactive glass, which is why the
/// hand-rolled picker buttons used to keep their stroke while dragged).
///
/// The label is caller-provided, so the caller owns the font: pass the custom
/// Obviously face where the design uses it, otherwise the native font.
public struct GlassButton<Label: View, S: InsettableShape>: View {
  public enum Interaction {
    /// Whole-button tap + press-to-hide-decor (drag arms immediately).
    case tap(() -> Void)
    /// Decor-hide only, armed after 8pt of travel — for a pill whose inner
    /// content owns the taps (a button group), so plain taps pass through.
    case group
  }

  private let shape: S
  private let kind: GlassDecorKind
  private let config: GlassTabBarConfig
  private let morphing: Bool
  private let glassID: GlassButtonID?
  private let interaction: Interaction
  private let label: Label

  @State private var pressed = false
  @State private var token = 0

  public init(
    _ shape: S,
    kind: GlassDecorKind = .neutral,
    config: GlassTabBarConfig,
    morphing: Bool = false,
    glassID: GlassButtonID? = nil,
    interaction: Interaction,
    @ViewBuilder label: () -> Label
  ) {
    self.shape = shape
    self.kind = kind
    self.config = config
    self.morphing = morphing
    self.glassID = glassID
    self.interaction = interaction
    self.label = label()
  }

  private var isAccent: Bool { kind == .accent }
  private var visible: Bool { !pressed && !morphing }

  public var body: some View {
    label
      .background(background)
      .glassEffect(isAccent ? config.accentGlass : config.pillGlass, in: shape)
      .modifier(GlassIDModifier(shape: shape, glassID: glassID))
      .glassDecoration(shape, kind: kind, config: config, visible: visible)
      // Accent buttons carry no drop shadow — their look is the rim + glow.
      .modifier(GlassShadowModifier(shape: shape, config: config, visible: visible, enabled: !isAccent))
      .contentShape(shape)
      .simultaneousGesture(pressGesture)
  }

  @ViewBuilder private var background: some View {
    if isAccent {
      shape.fill(config.accentFill)
    } else {
      frostFill(shape, config: config)
    }
  }

  private var pressGesture: some Gesture {
    // .group presses only arm after real travel so inner taps pass through.
    let minDistance: CGFloat = { if case .group = interaction { return 8 } else { return 0 } }()
    return DragGesture(minimumDistance: minDistance)
      .onChanged { _ in
        if !pressed { withAnimation(.easeInOut(duration: 0.12)) { pressed = true } }
      }
      .onEnded { value in
        endPress()
        if case .tap(let action) = interaction,
           hypot(value.translation.width, value.translation.height) < 12 {
          action()
        }
      }
  }

  private func endPress() {
    token += 1
    let current = token
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
      if token == current {
        withAnimation(.easeInOut(duration: 0.25)) { pressed = false }
      }
    }
  }
}

// glassEffectID / glassShadow are conditional; wrap them so the button body
// stays a single expression (no ternary-of-different-View-types).
private struct GlassIDModifier<S: InsettableShape>: ViewModifier {
  let shape: S
  let glassID: GlassButtonID?
  func body(content: Content) -> some View {
    if let glassID {
      content.glassEffectID(glassID.id, in: glassID.ns)
    } else {
      content
    }
  }
}

private struct GlassShadowModifier<S: InsettableShape>: ViewModifier {
  let shape: S
  let config: GlassTabBarConfig
  let visible: Bool
  let enabled: Bool
  func body(content: Content) -> some View {
    if enabled {
      content.glassShadow(shape, config: config, visible: visible)
    } else {
      content
    }
  }
}
