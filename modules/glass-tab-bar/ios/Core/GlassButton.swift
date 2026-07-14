import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass

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
    /// Whole-button tap + press-to-hide-decor.
    case tap(() -> Void)
    /// Decor-hide only — for a pill whose inner content owns the taps (a
    /// button group). The decor hides on touch-down exactly like .tap (Stage
    /// 44: consistent press feedback everywhere); the passive recognizer
    /// never steals the inner Buttons' taps.
    case group
  }

  private let shape: S
  private let kind: GlassDecorKind
  private let config: GlassTabBarConfig
  private let morphing: Bool
  private let glassID: GlassButtonID?
  private let interaction: Interaction
  /// Whether this button should track presses at all. The braindump header
  /// keeps BOTH clusters mounted in one slot (opacity swap) and the UIKit
  /// press recognizer bypasses SwiftUI's allowsHitTesting — without this
  /// gate the HIDDEN cluster's buttons would fire from touches on the
  /// visible ones (a ✕ tap was silently triggering the hidden Clear).
  private let pressEnabled: Bool
  private let label: Label

  @State private var pressed = false
  @State private var token = 0

  public init(
    _ shape: S,
    kind: GlassDecorKind = .neutral,
    config: GlassTabBarConfig,
    morphing: Bool = false,
    glassID: GlassButtonID? = nil,
    pressEnabled: Bool = true,
    interaction: Interaction,
    @ViewBuilder label: () -> Label
  ) {
    self.shape = shape
    self.kind = kind
    self.config = config
    self.morphing = morphing
    self.glassID = glassID
    self.pressEnabled = pressEnabled
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
      // UIKit-level press detection (see PressRecognizer): SwiftUI drag
      // gestures never receive touch-DOWN on some hosting arrangements (the
      // braindump header buffers touches until release — toolbar delivered
      // fine), while UIKit recognizers get touches regardless of view
      // delivery. The decor hides on touch-down for every kind (Stage 44),
      // and the recognizer never blocks the glass stretch or inner taps.
      .background(PressRecognizer(
        enabled: pressEnabled,
        armDistance: 0,
        onPress: {
          if !pressed { withAnimation(.easeInOut(duration: 0.12)) { pressed = true } }
        },
        onRelease: { isTap in
          endPress()
          if isTap, case .tap(let action) = interaction { action() }
        }
      ))
  }

  @ViewBuilder private var background: some View {
    if isAccent {
      shape.fill(config.accentFill)
    } else {
      frostFill(shape, config: config)
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

// MARK: - UIKit press detection

/// A pure touch OBSERVER that can't be cancelled by arbitration. The
/// interactive Liquid Glass claims stretch drags aggressively and would
/// cancel a `UILongPressGestureRecognizer` mid-drag — that was the "decor
/// returns while I'm still dragging, works only sometimes" bug (the standalone
/// braindump chrome has no GlassEffectContainer to tame the glass's claim, so
/// it's a coin-flip who wins). This recognizer neither prevents nor is
/// prevented by anything and never enters the exclusive-arbitration pool, so
/// its began→changed→ended stream survives the whole drag regardless.
final class ImmediatePressGestureRecognizer: UIGestureRecognizer {
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)
    state = .began
  }
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    if state == .began || state == .changed { state = .changed }
  }
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesEnded(touches, with: event)
    state = .ended
  }
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesCancelled(touches, with: event)
    state = .cancelled
  }
  // Observe only — never win/lose arbitration against the glass, scroll views
  // or inner Buttons.
  override func canBePrevented(by other: UIGestureRecognizer) -> Bool { false }
  override func canPrevent(_ other: UIGestureRecognizer) -> Bool { false }
}

/// Touch-down/up reporting that works where SwiftUI gestures don't: an
/// `ImmediatePressGestureRecognizer` attached to the button's UIKit ANCESTOR
/// (the recognizer fires for any touch in that subtree, so hit-testing and the
/// interactive glass stretch stay untouched; `cancelsTouchesInView = false`
/// keeps inner Buttons alive). The ancestor can be larger than the button, so
/// began-events are gated to the marker view's own bounds (the `.background`
/// sizes exactly to the button).
private struct PressRecognizer: UIViewRepresentable {
  /// Master switch — a disabled marker never starts tracking (used to mute
  /// the header's HIDDEN cluster, which shares the slot with the visible one).
  let enabled: Bool
  /// 0 = arm on touch-down; >0 = arm only after this travel.
  let armDistance: CGFloat
  let onPress: () -> Void
  let onRelease: (_ isTap: Bool) -> Void

  func makeUIView(context: Context) -> MarkerView {
    let view = MarkerView()
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ view: MarkerView, context: Context) {
    view.enabled = enabled
    view.armDistance = armDistance
    view.onPress = onPress
    view.onRelease = onRelease
  }

  final class MarkerView: UIView, UIGestureRecognizerDelegate {
    var enabled = true
    var armDistance: CGFloat = 0
    var onPress: (() -> Void)?
    var onRelease: ((Bool) -> Void)?

    private weak var host: UIView?
    private var recognizer: ImmediatePressGestureRecognizer?
    private var start: CGPoint = .zero
    private var armed = false
    private var tracking = false

    override func didMoveToWindow() {
      super.didMoveToWindow()
      if window == nil {
        if let recognizer { host?.removeGestureRecognizer(recognizer) }
        recognizer = nil
        host = nil
        return
      }
      guard recognizer == nil, let ancestor = hostingAncestor() else { return }
      let press = ImmediatePressGestureRecognizer(target: self, action: #selector(handle(_:)))
      press.cancelsTouchesInView = false
      press.delaysTouchesBegan = false
      press.delaysTouchesEnded = false
      press.delegate = self
      ancestor.addGestureRecognizer(press)
      recognizer = press
      host = ancestor
    }

    /// The recognizer must live on an ANCESTOR of the views that actually
    /// receive the touches. A `.background` representable is a SIBLING of the
    /// content (its own superview chain doesn't contain the touched glass
    /// views), so climb to the SwiftUI hosting root — the nearest ancestor
    /// whose class is a hosting view — or, failing that, the topmost view
    /// below the window. Touches anywhere in that subtree reach the
    /// recognizer; `handle` gates them to this button's own frame.
    private func hostingAncestor() -> UIView? {
      var candidate: UIView? = nil
      var node: UIView? = superview
      while let current = node, !(current is UIWindow) {
        candidate = current
        if String(describing: type(of: current)).contains("HostingView") {
          return current
        }
        node = current.superview
      }
      return candidate
    }

    @objc private func handle(_ r: ImmediatePressGestureRecognizer) {
      switch r.state {
      case .began:
        // The host ancestor can span more than this button — only track
        // touches that started inside the button's own frame (+2pt slack),
        // and only while this button is the ACTIVE one in its slot.
        let local = r.location(in: self)
        guard enabled, bounds.insetBy(dx: -2, dy: -2).contains(local) else {
          tracking = false
          return
        }
        tracking = true
        start = r.location(in: nil)
        armed = armDistance <= 0
        if armed { onPress?() }
      case .changed:
        guard tracking, !armed else { return }
        if distance(from: r) >= armDistance {
          armed = true
          onPress?()
        }
      case .ended:
        guard tracking else { return }
        tracking = false
        let isTap = distance(from: r) < 12
        if armed || isTap { onRelease?(isTap) }
        armed = false
      case .cancelled, .failed:
        guard tracking else { return }
        tracking = false
        if armed { onRelease?(false) }
        armed = false
      default:
        break
      }
    }

    private func distance(from r: UIGestureRecognizer) -> CGFloat {
      let p = r.location(in: nil)
      return hypot(p.x - start.x, p.y - start.y)
    }

    // Coexist with everything: the glass's own interaction, inner Buttons,
    // scroll views, RN's root touch handler.
    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool { true }
  }
}

public extension View {
  /// The GlassButton material + decor as a PASSIVE surface for containers
  /// (no gesture — the inner content owns its interactions, e.g. a picker
  /// shell with scrolling/tappable content). Same look as the buttons; the
  /// interactive glass still gives the touch shimmer for free.
  @ViewBuilder
  func glassSurface<S: InsettableShape>(
    _ shape: S, kind: GlassDecorKind = .neutral,
    config: GlassTabBarConfig, decorVisible: Bool = true
  ) -> some View {
    self
      .background(kind == .accent ? AnyView(shape.fill(config.accentFill))
                                  : AnyView(frostFill(shape, config: config)))
      .glassEffect(kind == .accent ? config.accentGlass : config.pillGlass, in: shape)
      .glassDecoration(shape, kind: kind, config: config, visible: decorVisible)
      .modifier(GlassShadowModifier(shape: shape, config: config, visible: decorVisible, enabled: kind != .accent))
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
