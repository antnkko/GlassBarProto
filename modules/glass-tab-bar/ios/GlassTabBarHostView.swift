import SwiftUI
import UIKit

// Fabric bridge for the tab bar: an @objc UIView the ObjC++ ComponentView
// mounts as its contentView. Props flow in through update(...), events flow
// out through @objc closure properties.
//
// The SwiftUI tree hangs off ONE UIHostingController whose root view reads an
// ObservableObject state holder. Prop updates mutate @Published state, so the
// tree keeps its identity — the core's .onChange reconciliation, matched
// glass morphs and springs all stay alive. Recreating the root view on every
// update would reset @State/@Namespace and kill the morphs.

final class GlassBridgeState: ObservableObject {
  @Published var config = GlassTabBarConfig()
  @Published var expanded = false
  @Published var activeTab = "home"
  @Published var lastSeq = 0
  @Published var collapsed = false
  @Published var option = 0

  var onTabPress: ((String, Int) -> Void)?
  var onSubTabPress: ((String, Int) -> Void)?
  var onExpandChange: ((Bool, Int) -> Void)?
  var onToolbarPress: ((String, Int) -> Void)?
}

private struct GlassTabBarRoot: View {
  @ObservedObject var state: GlassBridgeState

  var body: some View {
    GlassTabBarView(
      config: state.config,
      expanded: state.expanded,
      activeTab: state.activeTab,
      lastSeq: state.lastSeq,
      collapsed: state.collapsed,
      onTabPress: { [weak state] tab, seq in state?.onTabPress?(tab, seq) },
      onSubTabPress: { [weak state] tab, seq in state?.onSubTabPress?(tab, seq) },
      onExpandChange: { [weak state] expanded, seq in state?.onExpandChange?(expanded, seq) }
    )
  }
}

@objc(GlassTabBarHostView)
public final class GlassTabBarHostView: UIView {
  private let state = GlassBridgeState()
  private let host: UIHostingController<GlassTabBarRoot>

  @objc public var onTabPress: ((NSString, NSInteger) -> Void)?
  @objc public var onSubTabPress: ((NSString, NSInteger) -> Void)?
  @objc public var onExpandChange: ((Bool, NSInteger) -> Void)?

  public override init(frame: CGRect) {
    host = UIHostingController(rootView: GlassTabBarRoot(state: state))
    super.init(frame: frame)

    // The bar is a floating overlay: it must not inherit safe-area/keyboard
    // insets from the hosting controller, and the glass needs a clear stage.
    host.view.backgroundColor = .clear
    host.safeAreaRegions = []
    host.view.frame = bounds
    host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(host.view)

    state.onTabPress = { [weak self] tab, seq in self?.onTabPress?(tab as NSString, seq) }
    state.onSubTabPress = { [weak self] tab, seq in self?.onSubTabPress?(tab as NSString, seq) }
    state.onExpandChange = { [weak self] expanded, seq in self?.onExpandChange?(expanded, seq) }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  @objc public func update(
    expanded: Bool,
    activeTab: String,
    lastSeq: Int,
    collapsed: Bool,
    config: [String: Any]
  ) {
    let next = GlassTabBarConfig(bridge: config)
    if state.config != next { state.config = next }
    if state.expanded != expanded { state.expanded = expanded }
    if state.activeTab != activeTab { state.activeTab = activeTab }
    if state.lastSeq != lastSeq { state.lastSeq = lastSeq }
    if state.collapsed != collapsed { state.collapsed = collapsed }
  }
}

// MARK: - Bridge dictionary → config

extension GlassTabBarConfig {
  /// Maps the NSDictionary built by the ComponentView from the codegen C++
  /// struct. Missing/mistyped keys fall back to the struct defaults.
  init(bridge: [String: Any]) {
    self.init()
    if let v = bridge["milkOpacity"] as? Double { milkOpacity = v }
    if let v = bridge["accentHex"] as? String, !v.isEmpty { accentHex = v }
    if let v = bridge["lightHex"] as? String, !v.isEmpty { lightHex = v }
    if let v = bridge["midHex"] as? String, !v.isEmpty { midHex = v }
    if let v = bridge["highlightBlend"] as? String, !v.isEmpty { highlightBlend = v }
    if let v = bridge["highlightOpacity"] as? Double { highlightOpacity = v }
    if let v = bridge["appearance"] as? String, !v.isEmpty { appearance = v }
    if let v = bridge["containerSpacing"] as? Double { containerSpacing = v }
    if let v = bridge["springDuration"] as? Double, v > 0 { springDuration = v }
    if let v = bridge["springBounce"] as? Double { springBounce = v }
    if let v = bridge["pillWidth"] as? Double, v > 0 { pillWidth = v }
    if let v = bridge["pillHeight"] as? Double, v > 0 { pillHeight = v }
    if let v = bridge["innerPadding"] as? Double { innerPadding = v }
    if let v = bridge["gap"] as? Double { gap = v }
    if let v = bridge["hPadding"] as? Double { hPadding = v }
    if let v = bridge["subTabSpacing"] as? Double { subTabSpacing = v }
    if let v = bridge["iconSize"] as? Double, v > 0 { iconSize = v }
    if let v = bridge["plusIconSize"] as? Double, v > 0 { plusIconSize = v }
    if let v = bridge["strokeMode"] as? String, !v.isEmpty { strokeMode = v }
    if let v = bridge["glassVariant"] as? String, !v.isEmpty { glassVariant = v }
    if let v = bridge["glassInteractive"] as? Bool { glassInteractive = v }
    if let v = bridge["shadowMode"] as? String, !v.isEmpty { shadowMode = v }
    if let v = bridge["shadowOpacityScale"] as? Double { shadowOpacityScale = v }
    if let v = bridge["shadowRadiusScale"] as? Double { shadowRadiusScale = v }
  }
}
