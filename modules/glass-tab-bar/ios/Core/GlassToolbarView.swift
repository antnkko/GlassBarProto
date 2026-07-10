import SwiftUI
import UIKit

// The Liquid Glass top toolbar. Wrapper-agnostic, same rules as the tab bar:
// content lives INSIDE the glass views (press stretch + morph carry it),
// milkiness is an in-material tint, and every slot keeps a stable
// glassEffectID so switching between the 8 Figma configurations morphs the
// leading/trailing elements (avatar ↔ ghost button ↔ button group ↔ CTA)
// with the same matched-geometry mechanic the bar uses.
//
// Figma: iOS 27 / node 278:2416 "Toolbar — Dev spec", 8 rows:
//   1  —          —                        avatar
//   2  back       title + subtitle         avatar
//   3  back       title + accent subtitle  translate ghost
//   4  back       —                        —
//   5  settings   —                        close ghost
//   6  back       —                        button group (Aa | more)
//   7  back       progress (4 segments)    —
//   8  back       —                        primary CTA pill
struct GlassToolbarView: View {
  let config: GlassTabBarConfig
  /// Which toolbar configuration to show: 1...8, or 0 for none.
  let option: Int

  var onPress: (_ element: String, _ seq: Int) -> Void = { _, _ in }

  // The option animates locally so a panel change plays the morph spring.
  @State private var localOption = 0
  @State private var seq = 0

  @Namespace private var glassNS

  // Figma spec constants (pt).
  private let ghostSize: Double = 48
  private let avatarPhotoSize: Double = 42
  // Measured from the Figma render (node 273:3944): the CTA pill is 52pt
  // tall (117 wide with the 32pt paddings) — the CSS-ish py values in the
  // generated context are misleading, the actual auto-layout height wins.
  private let ctaHeight: Double = 52
  private let groupZoneSize: Double = 48

  var body: some View {
    GlassEffectContainer(spacing: config.containerSpacing) {
      ZStack {
        centerBlock

        HStack(spacing: 0) {
          leadingElement
          Spacer(minLength: 0)
          trailingElement
        }
      }
      .padding(.horizontal, 20)
    }
    // Same trick as the bar: recreate the glass when appearance flips.
    .id("scheme-\(config.appearance)")
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(InterfaceStylePinner(style: config.interfaceStyle))
    .onAppear { localOption = option }
    .onChange(of: option) { _, next in
      withAnimation(config.spring) { localOption = next }
    }
  }

  // MARK: - Material (same recipe as the bar pills)

  private var pillGlass: Glass {
    var glass: Glass = .regular
    if config.milkOpacity > 0.01 {
      glass = glass.tint(config.milkColor.opacity(config.milkOpacity))
    }
    return glass.interactive()
  }

  // MARK: - Slots

  // Leading slot: a ghost circle in every configuration that has one.
  // Stable id "tb-lead" — switching 4 ↔ 5 morphs back ↔ settings in place.
  @ViewBuilder
  private var leadingElement: some View {
    switch localOption {
    case 2, 3, 4, 6, 7, 8:
      ghostButton("tb_back", iconSize: 20, element: "back")
        .glassEffectID("tb-lead", in: glassNS)
    case 5:
      ghostButton("tb_settings", iconSize: 24, element: "settings", color: neutralDark)
        .glassEffectID("tb-lead", in: glassNS)
    default:
      EmptyView()
    }
  }

  // Trailing slot: avatar / ghost / button group / CTA all share "tb-trail",
  // so flipping configurations runs the glass morph between shapes.
  @ViewBuilder
  private var trailingElement: some View {
    switch localOption {
    case 1, 2:
      avatar
    case 3:
      ghostButton("tb_translate", iconSize: 28, element: "translate")
        .glassEffectID("tb-trail", in: glassNS)
    case 5:
      ghostButton("tb_close", iconSize: 20, element: "close")
        .glassEffectID("tb-trail", in: glassNS)
    case 6:
      buttonGroup
    case 8:
      ctaButton
    default:
      EmptyView()
    }
  }

  // Center block sits on the backdrop without glass (as in the spec) — the
  // top scroll edge effect provides its legibility, like native nav titles.
  @ViewBuilder
  private var centerBlock: some View {
    switch localOption {
    case 2:
      titleBlock(subtitleColor: config.mid)
    case 3:
      titleBlock(subtitleColor: config.accent)
    case 7:
      progressBlock
    default:
      EmptyView()
    }
  }

  // MARK: - Pieces (content INSIDE the glass view — the v2.2 lesson)

  private func ghostButton(
    _ iconName: String, iconSize: Double, element: String, color: Color? = nil
  ) -> some View {
    ZStack {
      icon(iconName, size: iconSize, color: color ?? config.mid, multiply: useMultiply)
    }
    .frame(width: ghostSize, height: ghostSize)
    .glassEffect(pillGlass, in: Circle())
    .contentShape(Circle())
    .onTapGesture { pressed(element) }
  }

  private var avatar: some View {
    ZStack {
      Image("tb_avatar")
        .resizable()
        .scaledToFill()
        .frame(width: avatarPhotoSize, height: avatarPhotoSize)
        .clipShape(Circle())
    }
    .frame(width: ghostSize, height: ghostSize)
    .glassEffect(pillGlass, in: Circle())
    .glassEffectID("tb-trail", in: glassNS)
    .contentShape(Circle())
    .onTapGesture { pressed("avatar") }
  }

  // Figma: pill h48, px 6, two 48pt icon zones with a 2×24 divider between.
  private var buttonGroup: some View {
    HStack(spacing: 3) {
      groupZone("tb_aa", element: "aa")
      Capsule()
        .fill(dividerColor)
        .frame(width: 2, height: 24)
        .blendMode(useMultiply ? .multiply : .normal)
      groupZone("tb_more", element: "more")
    }
    .padding(.horizontal, 6)
    .frame(height: ghostSize)
    .glassEffect(pillGlass, in: Capsule())
    .glassEffectID("tb-trail", in: glassNS)
  }

  private func groupZone(_ iconName: String, element: String) -> some View {
    ZStack {
      icon(iconName, size: 28, color: neutralDark, multiply: useMultiply)
    }
    .frame(width: groupZoneSize, height: groupZoneSize)
    .contentShape(Rectangle())
    .onTapGesture { pressed(element) }
  }

  // Figma: accent pill h≈60, px 32, "Button" semibold 18 white. The solid
  // fill lives in the glass content (same as the bar's plus button) so the
  // interactive stretch and the morph carry it; the glass rim replaces the
  // mock's inner white glow.
  private var ctaButton: some View {
    // The fill is a BACKGROUND of the text, not a ZStack sibling: a bare
    // Capsule shape is greedy and would stretch the pill across all the
    // free toolbar width. Background sizes to the label (design: px 32).
    Text("Button")
      .font(.system(size: 18, weight: .semibold))
      .tracking(0.18)
      .foregroundStyle(.white)
      .padding(.bottom, 4)
      .padding(.horizontal, 32)
      .frame(height: ctaHeight)
      .background(Capsule().fill(config.accent))
      .glassEffect(.regular.tint(config.accent).interactive(), in: Capsule())
      .glassEffectID("tb-trail", in: glassNS)
      .contentShape(Capsule())
      .onTapGesture { pressed("cta") }
  }

  // Figma: title 28 Obviously Narrow Bold (SF condensed bold as surrogate),
  // subtitle 14 medium, gap 2, block nudged up 4pt (pb-8 in the mock).
  private func titleBlock(subtitleColor: Color) -> some View {
    VStack(spacing: 2) {
      Text("Title")
        .font(.system(size: 28, weight: .bold))
        .fontWidth(.condensed)
        .tracking(0.56)
        .foregroundStyle(titleColor)
      Text("Subtitle")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(subtitleColor)
        // Subtitle lets backdrop light through, like the group icons.
        // Multiply only darkens, so dark appearance stays normal.
        .blendMode(config.appearance != "dark" ? .multiply : .normal)
    }
    .offset(y: -4)
  }

  // Figma: 4 segments 28×4, gap 6, theme accent, steps 3-4 at 25%.
  private var progressBlock: some View {
    HStack(spacing: 6) {
      ForEach(0..<4) { step in
        Capsule()
          .fill(config.accent)
          .opacity(step < 2 ? 1 : 0.25)
          .frame(width: 28, height: 4)
      }
    }
  }

  private func icon(_ name: String, size: Double, color: Color, multiply: Bool = false) -> some View {
    Image(name)
      .renderingMode(.template)
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .foregroundStyle(color)
      .blendMode(multiply ? .multiply : .normal)
  }

  // Design: the button-group state renders its icons and divider with
  // mix-blend-multiply so backdrop light passes through. Multiply only
  // darkens, so dark appearance falls back to normal (same rule as the
  // bar's active highlight).
  private var useMultiply: Bool {
    localOption == 6 && config.appearance != "dark"
  }

  private var titleColor: Color {
    config.appearance == "dark" ? Color(hexString: "#F5F5F7") ?? .white : .black
  }

  private var dividerColor: Color {
    config.appearance == "dark"
      ? Color.white.opacity(0.14)
      : Color(hexString: "#F1F1F1") ?? Color.black.opacity(0.06)
  }

  // Design token neutral/dark — the settings icon and the button-group icons
  // are darker than the mid inactive tone. Dark-mode counterpart is our own
  // light equivalent (the mock only specifies light).
  private var neutralDark: Color {
    config.appearance == "dark"
      ? (Color(hexString: "#C6C8CC") ?? .white)
      : (Color(hexString: "#4B4E52") ?? .black)
  }

  // MARK: - Interactions

  private func pressed(_ element: String) {
    seq += 1
    onPress(element, seq)
  }
}
