import SwiftUI
import UIKit

// The morphing Liquid Glass tab bar. Wrapper-agnostic: no Expo imports,
// state comes in as plain values, interactions go out via closures.
//
// Morph mechanic: the collapsed right pill and the expanded bubble share
// glassEffectID "bubble" inside one GlassEffectContainer -> SwiftUI runs a
// matched-geometry glass morph between them. "home" keeps a stable id in
// both states so it never re-materializes. Only "plus" enters/exits.
//
// v2.2: back to the v1 structure — .glassEffect() is applied directly onto
// the pill CONTENT (highlight + icon). That is what makes the material feel
// alive: the interactive press stretches the whole pill including content,
// and during the morph the system blurs/refracts the content inside the
// glass (the "gooey" transition). The cost is Liquid Glass vibrancy slightly
// re-tinting the content on extreme backdrops; the milky white tint in the
// material keeps that subtle.
struct GlassTabBarView: View {
  let config: GlassTabBarConfig
  // Controlled values from RN + seq handshake (see reconcile()).
  let expanded: Bool
  let activeTab: String
  let lastSeq: Int
  /// Instagram-style minimize: scroll-down shrinks the bar toward the bottom.
  let collapsed: Bool

  var onTabPress: (_ tab: String, _ seq: Int) -> Void = { _, _ in }
  var onSubTabPress: (_ tab: String, _ seq: Int) -> Void = { _, _ in }
  var onExpandChange: (_ expanded: Bool, _ seq: Int) -> Void = { _, _ in }

  @State private var localExpanded = false
  @State private var localActiveTab = "home"
  @State private var seq = 0

  // Which element is being pressed, and whether a morph is in flight — the
  // stroke hides during either and returns only when everything settles.
  @State private var pressedID: String?
  @State private var morphing = false
  // Monotonic token so a delayed press-clear is cancelled by a re-press.
  @State private var pressToken = 0

  @Namespace private var glassNS
  @Namespace private var highlightNS

  private let subTabs = ["squad", "chat", "play"]

  var body: some View {
    GlassEffectContainer(spacing: config.containerSpacing) {
      HStack(spacing: localExpanded ? config.gap : 0) {
        homePill

        if localExpanded {
          expandedBubble
        } else {
          Spacer(minLength: 0)
          plusButton
          Spacer(minLength: 0)
          collapsedRightPill
        }
      }
      .padding(.horizontal, config.hPadding)
    }
    // Recreate the glass when appearance flips: a trait change alone does
    // not re-render an already-applied glass effect.
    .id("scheme-\(config.appearance)")
    .scaleEffect(collapsed ? 0.8 : 1.0, anchor: .bottom)
    .animation(config.spring, value: collapsed)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .background(InterfaceStylePinner(style: config.interfaceStyle))
    .onAppear { syncFromProps(animated: false) }
    .onChange(of: expanded) { _, _ in reconcile() }
    .onChange(of: activeTab) { _, _ in reconcile() }
    .onChange(of: lastSeq) { _, _ in reconcile() }
  }

  // MARK: - Material

  // Milkiness lives IN the material as a tint (see config.pillGlass) so
  // edges, the press stretch/shimmer and the morph render natively on it.
  private var pillGlass: Glass { config.pillGlass }

  // MARK: - Pieces (v1 pattern: content INSIDE the glass view)

  private var homePill: some View {
    let active = !localExpanded
    return ZStack {
      frostFill(Capsule(), config: config)
      if active {
        highlightFill
          .padding(config.innerPadding)
      }
      icon("tab_home", size: config.iconSize, color: active ? config.accent : config.mid)
    }
    .frame(width: config.pillWidth, height: config.pillHeight)
    .glassEffect(pillGlass, in: Capsule())
    .glassEffectID("home", in: glassNS)
    .glassDecoration(Capsule(), kind: .neutral, config: config, visible: strokeVisible("home"))
    .glassShadow(.neutral, config: config)
    .contentShape(Capsule())
    .gesture(tapPressGesture("home") { homeTapped() })
  }

  private var plusButton: some View {
    ZStack {
      // Fully opaque accent: the glass tint alone reads slightly translucent.
      // The fill lives in the glass content, so press-stretch and the
      // matched-geometry exit still carry it.
      Capsule().fill(config.accent)
      icon("tab_plus", size: config.plusIconSize, color: .white)
    }
    .frame(width: config.pillWidth, height: config.pillHeight)
    .glassEffect(config.accentGlass, in: Capsule())
    .glassEffectID("plus", in: glassNS)
    .glassEffectTransition(.matchedGeometry)
    .glassDecoration(Capsule(), kind: .accent, config: config)
    .glassShadow(.accent, config: config)
    .contentShape(Capsule())
    .onTapGesture { plusTapped() }
  }

  private var collapsedRightPill: some View {
    ZStack {
      frostFill(Capsule(), config: config)
      icon("tab_squad", size: config.iconSize, color: config.mid)
    }
    .frame(width: config.pillWidth, height: config.pillHeight)
    .glassEffect(pillGlass, in: Capsule())
    .glassEffectID("bubble", in: glassNS)
    .glassDecoration(Capsule(), kind: .neutral, config: config, visible: strokeVisible("right"))
    .glassShadow(.neutral, config: config)
    .contentShape(Capsule())
    .gesture(tapPressGesture("right") { expandTapped() })
  }

  private var expandedBubble: some View {
    ZStack {
      frostFill(Capsule(), config: config)
      HStack(spacing: config.subTabSpacing) {
        ForEach(subTabs, id: \.self) { tab in
          subTab(tab)
        }
      }
      .padding(config.innerPadding)
    }
    .frame(maxWidth: .infinity)
    .frame(height: config.pillHeight)
    // One drag gesture over the whole bubble: touch down and slide across the
    // sub-tabs and the selection follows the finger, native-UITabBar-style.
    // A tap is just a zero-length drag, so taps keep working.
    .overlay {
      GeometryReader { geo in
        Color.clear
          .contentShape(Rectangle())
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                if pressedID != "bubble" { pressedID = "bubble" }
                selectSubTab(atX: value.location.x, width: geo.size.width)
              }
              .onEnded { _ in endPress() }
          )
      }
    }
    .glassEffect(pillGlass, in: Capsule())
    .glassEffectID("bubble", in: glassNS)
    .glassDecoration(Capsule(), kind: .neutral, config: config, visible: strokeVisible("bubble"))
    .glassShadow(.neutral, config: config)
  }

  private func subTab(_ tab: String) -> some View {
    let active = localActiveTab == tab
    return ZStack {
      if active {
        highlightFill
          .matchedGeometryEffect(id: "highlight", in: highlightNS)
      }
      icon("tab_\(tab)", size: config.iconSize, color: active ? config.accent : config.mid)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // Figma spec: the highlight is mix-blend-multiply — it tints what's under
  // it (glass + backdrop light) instead of covering it with a flat fill.
  // In dark appearance multiply would only darken an already-dark backdrop
  // (the dim accent tone would vanish), so dark renders with normal blend.
  @ViewBuilder
  private var highlightFill: some View {
    if config.highlightBlend == "multiply" && config.appearance != "dark" {
      Capsule()
        .fill(config.light)
        .opacity(config.highlightOpacity)
        .blendMode(.multiply)
    } else {
      Capsule()
        .fill(config.light.opacity(config.highlightOpacity))
    }
  }

  private func icon(_ name: String, size: Double, color: Color) -> some View {
    Image(name)
      .renderingMode(.template)
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .foregroundStyle(color)
  }

  // MARK: - Feedback state

  // One gesture per pill: press detection AND the tap action. A separate
  // simultaneous press-detector next to .onTapGesture silenced the tap
  // entirely (verified with real XCUITest taps), so the tap is the drag's
  // release instead: near-zero translation on end = a tap.
  private func tapPressGesture(_ id: String, onTap: @escaping () -> Void) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { _ in if pressedID != id { pressedID = id } }
      .onEnded { value in
        endPress()
        if hypot(value.translation.width, value.translation.height) < 12 { onTap() }
      }
  }

  // The interactive stretch bounces on release, so the stroke must come back
  // only after it settles: clear the press a beat later, cancelled by a
  // re-press via the token.
  private func endPress() {
    pressToken += 1
    let token = pressToken
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      if pressToken == token { pressedID = nil }
    }
  }

  private func strokeVisible(_ id: String) -> Bool {
    pressedID != id && !morphing
  }

  // Runs a spring morph while holding `morphing` true, so every element's
  // stroke fades during the transition. `.removed` fires completion only once
  // the spring has fully settled — past the bounce — so the stroke returns
  // after the button is truly back at rest, not mid-overshoot.
  private func morph(_ body: @escaping () -> Void) {
    morphing = true
    withAnimation(config.spring, completionCriteria: .removed) {
      body()
    } completion: {
      morphing = false
    }
  }

  // MARK: - Interactions (optimistic: animate first, report up after)

  private func homeTapped() {
    guard localExpanded else { return }
    seq += 1
    morph {
      localExpanded = false
      localActiveTab = "home"
    }
    onTabPress("home", seq)
    onExpandChange(false, seq)
  }

  private func expandTapped() {
    seq += 1
    morph {
      localExpanded = true
      localActiveTab = "squad"
    }
    onTabPress("squad", seq)
    onExpandChange(true, seq)
  }

  private func plusTapped() {
    seq += 1
    onTabPress("plus", seq)
  }

  private func subTabTapped(_ tab: String) {
    guard localActiveTab != tab else { return }
    seq += 1
    withAnimation(config.spring) {
      localActiveTab = tab
    }
    onSubTabPress(tab, seq)
  }

  // Maps a finger x-position over the bubble to a sub-tab and selects it live.
  private func selectSubTab(atX x: CGFloat, width: CGFloat) {
    guard width > 0 else { return }
    let index = min(subTabs.count - 1, max(0, Int(x / (width / CGFloat(subTabs.count)))))
    subTabTapped(subTabs[index])
  }

  // Apply controlled props only when RN has caught up with our optimistic
  // state (lastSeq >= seq) AND the value actually differs. A stale echo
  // during rapid taps has lastSeq < seq and is ignored.
  private func reconcile() {
    guard lastSeq >= seq else { return }
    guard expanded != localExpanded || activeTab != localActiveTab else { return }
    syncFromProps(animated: true)
  }

  private func syncFromProps(animated: Bool) {
    if animated {
      morph {
        localExpanded = expanded
        localActiveTab = activeTab
      }
    } else {
      localExpanded = expanded
      localActiveTab = activeTab
    }
  }
}

// MARK: - Appearance pinning

// Liquid Glass resolves light/dark from the UIKit trait collection of the
// hosting view hierarchy, not from the SwiftUI environment. This invisible
// helper climbs to the nearest UIKit hosting view and pins its
// overrideUserInterfaceStyle. Paired with .id("scheme-…") above, which
// forces the glass to be recreated after the trait change (a trait change
// alone does not re-render an applied glass effect).
// Internal: the toolbar (GlassToolbarView) pins its own hosting view too.
struct InterfaceStylePinner: UIViewRepresentable {
  let style: UIUserInterfaceStyle

  func makeUIView(context: Context) -> PinnerView {
    PinnerView(style: style)
  }

  func updateUIView(_ view: PinnerView, context: Context) {
    view.apply(style)
  }

  final class PinnerView: UIView {
    private var style: UIUserInterfaceStyle

    init(style: UIUserInterfaceStyle) {
      self.style = style
      super.init(frame: .zero)
      isUserInteractionEnabled = false
      backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      apply(style)
    }

    func apply(_ style: UIUserInterfaceStyle) {
      self.style = style
      guard window != nil else { return }
      // Find the SwiftUI hosting view that contains this whole component and
      // pin it — that covers every glass-backing view in the subtree without
      // touching the rest of the React Native hierarchy.
      var candidate: UIView? = superview
      while let current = candidate {
        if String(describing: type(of: current)).contains("HostingView") {
          current.overrideUserInterfaceStyle = style
          return
        }
        candidate = current.superview
      }
      // Fallback: pin the immediate superview.
      superview?.overrideUserInterfaceStyle = style
    }
  }
}
