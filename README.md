# GlassBarProto — Liquid Glass morphing tab bar

Standalone prototype of Numo's custom iOS 26 **Liquid Glass** tab bar, to validate
the native feel of the morph interaction before porting it into the main app.

## The interaction
- **Default:** home pill · center **+** button · right pill (squad), each its own glass shape.
- **Tap the right pill →** it morphs into one glass **bubble** with 3 sub-tabs (Squad / Chat / Play);
  home compacts to inactive, the **+** button disappears. Real matched-geometry glass morph.
- **Tap home →** collapse back. Sub-tab taps slide the active highlight (matched geometry).

## Why native SwiftUI (not a pure-RN glass lib)
The pill→bubble morph needs SwiftUI `glassEffectID` + `@Namespace` matched-geometry inside a
`GlassEffectContainer`. UIKit (and therefore every RN glass wrapper — `@callstack/liquid-glass`,
`expo-glass-effect`) exposes only `UIGlassContainerEffect.spacing` proximity-merge, which can't
express this morph. So the **bar chrome is native SwiftUI**; RN owns screens, state and the debug panel.

- Native module: `modules/glass-tab-bar/`
  - `ios/Core/` — wrapper-agnostic SwiftUI (zero Expo imports): `GlassTabBarView.swift`,
    `GlassTabBarConfig.swift`, `Haptics.swift`. **This is what ports into Numo** (re-wrap in Fabric).
  - `ios/GlassTabBar{Module,ExpoView}.swift` — the Expo Modules host wrapper (`ExpoSwiftUI.View`
    + `WithHostingView`, `@Field` props, `EventDispatcher`).
- Optimistic state: native morphs instantly on tap and reports events up; RN echoes back via
  `lastSeq` so controlled props never fight the animation (see `src/state/tabState.ts`).

## Requirements
- Xcode 26+, iOS 26 target. RN 0.86 + expo-modules-core 57 (New Architecture).
- CocoaPods: use Homebrew's `pod` with a UTF-8 locale — the system Ruby 2.6 breaks Expo's scripts:
  `cd ios && LANG=en_US.UTF-8 /opt/homebrew/bin/pod install`

## Run
```bash
npm install
cd ios && LANG=en_US.UTF-8 /opt/homebrew/bin/pod install && cd ..
npx react-native start                       # Metro
# Simulator (layout/logic):
npx react-native run-ios --simulator "iPhone 17 Pro"
# Device — REQUIRED for the real material + haptics + 120Hz:
#   1. open ios/GlassBarProto.xcworkspace, select your Team under Signing & Capabilities
#   2. npx react-native run-ios --device "antnkko"
#   3. feel-check MUST be a Release build (Debug lags at 120Hz):
#      npx react-native run-ios --mode Release --device "antnkko"
```

## Tuning the material (no code edits)
Tap the **⚙︎** (top-right) → live sliders/segments for: glass variant, tint + opacity per element,
coalescence spacing, spring duration/bounce, plus-button transition (matchedGeometry vs materialize),
haptics, all sizes, scrim, color scheme. **Copy JSON** exports the current config; settings persist
(AsyncStorage). Defaults live in `src/debug/configSchema.ts` and mirror the Swift `GlassConfigRecord`.

## Notes
- Liquid Glass renders subtly on the **Simulator** — refraction/blur and haptics only fully appear on device.
- Dev-only helpers in `App.tsx`: `DEV_AUTOPLAY` (cycles states for headless recording) and a
  `glassbar://expand|collapse|sub/<tab>` deep link. Both off/no-op in normal use.
