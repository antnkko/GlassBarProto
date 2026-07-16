# RN Animation Port — Onboarding + Braindump Open/Close

## Context

The onboarding flow (entrance cascade → overlay → 3-act morph) and the braindump
open/close slides currently run as native SwiftUI inside the `NumoFlow` Fabric
overlay (`ios/Numo/`). A previous partial port (Stages 41–47) moved only the
bottom-bar chip↔picker cluster to RN and it janks. This task ports **both
animation flows fully to React Native** (Reanimated 4, UI-thread worklets),
preserving exact look-and-feel, and fixes the existing cluster jank.

User-confirmed decisions:
- **Full RN rebuild** of the flow screens (Stage-1 list, onboarding overlay,
  redesigned canvas). Native flow stays behind a **debug toggle** for
  side-by-side comparison.
- **Top nav stays native Fabric** (user requirement): the redesigned screen's
  chrome (✕ + publicity pill / Clear + ✓) gets wrapped as a new small Fabric
  leaf reusing the existing SwiftUI `GlassButton`s; RN animates only its
  container (transform/opacity — cheap on Fabric host views).
- **Fix the picker-cluster jank** in the same task.
- **iOS only.**

## Source of truth

- `ios/Numo/Morph/MorphChoreo.swift` — ALL timing/spring constants (read, verified).
- `ios/Numo/Stage3_Redesign/RedesignedScreen.swift` — `runReleaseTimeline` /
  `runSlideUpTimeline` / `runSlideDownTimeline`, header-crop mechanism (read).
- `ios/Numo/Stage1_BrainDump/BrainDumpEntrance.swift`, `Stage2_Onboarding/OnboardingOverlay.swift`,
  `Flow/AppFlowCoordinator.swift`, `Metrics.swift` — read per-stage during implementation.
- Handoff specs (pre-converted to Reanimated):
  - `/Users/ilyssssha/Desktop/New Braindump/handoff/spec/` (`02_SCREENS.md`,
    `03_ANIMATIONS.md`, `04_SWIFTUI_TO_RN.md`, `data/choreography.json`, `reference/morph.mp4`)
  - `/Users/ilyssssha/Desktop/Text Dump Open:Close Animation/Handoff - Braindump Modal Animations/`
    (`SPEC.md`, `constants.md`)
- Spring conversion convention: `src/braindump/motion.ts`
  (`.spring(duration:d, bounce:b)` → `{duration: d*1000, dampingRatio: 1−b}`;
  `.spring(response:r, dampingFraction:f)` → `{mass:1, stiffness:(2π/r)², damping: f·2·√stiffness}`).

## Performance ground rules (fixes for the previous port's root causes)

1. All timelines = shared values + worklets; **zero setState mid-animation**
   (React commits only at timeline boundaries; pre-mount both states and flip
   opacity/transform via shared values).
2. **Transform/opacity only** wherever visually possible. Never spring
   height/top/margin over a subtree. Where a real size change is unavoidable,
   animate an **absolute childless leaf** (its layout doesn't touch siblings).
3. **Never animate expo-blur `intensity` per frame** — cross-fade fixed-intensity
   blurs via opacity instead.
4. **Never resize `LiquidGlassView` with children per frame** — glass shell
   becomes a childless leaf; content lives in overlay siblings.
5. Worklets read shared values, not JS-captured state (`openH` etc.).
6. No new dependencies. Keyboard: `focus()` at t=0 of open, `Keyboard.dismiss()`
   at t=0 of close (system animation runs concurrently, as native does).

## Stages

### Stage 49 — Foundation + debug toggle ✅ (commit 5fb9001)
- [x] `src/flow/choreo.ts` — mirror `MorphChoreo.swift` 1:1 (names preserved):
      drawDown, consolePull=30, consoleGrowth=700, stretchDuration=1500,
      overlayFadeOut=180, coverStart≈250, riseSpring {d:380, ratio:0.88},
      coverHold=200, retractSpring {d:600, ratio:0.82}, ghostRise=120,
      newHeaderSpring {d:500, ratio:0.60}, newHeaderDrop=−28,
      bottomBarSpring {d:550, ratio:0.78}, bottomBarRise=280, buttonsLead=300,
      buttonsStagger=60, textAfterButtons=450, placeholderSwap smooth(450);
      slideRiseSpring {d:180, ratio:1.0}, slideRetractSpring {d:320, ratio:0.66},
      slideButtonsLead=100, slideBottomBarRise=40, slideBottomBarDelay=60,
      slideCloseStretch=24, stretchSpring {d:100, ratio:0.8}, dropSpring {d:320, ratio:1.0},
      bgFade easeOut 180, bottomFade easeOut 120; entrance cascade spring
      {mass:1, stiffness:416, damping:24.3} + offsets 30/30/50/70/90.
- [x] `src/flow/flowState.ts` — RN flow state machine (route/stage/morphPhase),
      `numo.hasSeenOnboarding` via AsyncStorage; "reset onboarding" clears both
      AsyncStorage and the native UserDefaults (existing `mode:'reset'` path).
- [x] Debug toggle `rnFlow: boolean` in AppConfig (persisted, segmented switch
      in `src/debug/DebugPanel.tsx`); `App.tsx` branches the "+" open between
      `NumoFlowView` (unchanged) and the new RN flow root.
- [x] Extract `redesign_bg` from the Xcode asset catalog into `src/assets/`
      (cross/picker_checkmark not needed — the chrome stays native).

### Stage 50 — Redesigned canvas screen, static, in RN
- [ ] New Fabric leaf **`NumoChrome`** (pattern of `NumericText`: codegen spec in
      `modules/glass-tab-bar/src/`, ComponentView + host in `ios/Numo/`),
      hosting the existing SwiftUI chrome verbatim (GlassButton ✕ +
      `PublicityTagsPill` / Clear + ✓ clusters, internal blur+opacity swap on
      native springs). Props: `pickerOpen`, `tag`, `morphing`; events
      `onClose`/`onClear`/`onConfirm`. RN animates only its container.
- [ ] `src/flow/RedesignedCanvas.tsx` — full-bleed `redesign_bg` Image, white
      sheet (top radius 48, top at safeTop), placeholder + TextInput
      (ObviouslyNarrow-Bold 40 / 46 line height / tracking), reuse
      `BraindumpBottomBar` cluster + `NumoChrome`.
- [ ] Pixel-compare the static resting state vs native cold boot (debug toggle).

### Stage 51 — Open/close slide animations (RN)
- [ ] Shared values: `sheetTop` (screenH→0→safeTop), `closeY` (0→−24→dropHeight),
      `bgShown` (0|1 flip under cover — no setState), `bgFade`, `chromeIn`, `barIn`.
- [ ] OPEN: focus at t=0; rise 180ms flat; bg flip at 180ms (worklet); drop with
      bounce (ratio 0.66); chrome at downDelay+100ms (−28→0 + fade);
      bar at 60ms from rise=40. All `withDelay`/`withSequence` on UI thread.
- [ ] CLOSE: header-crop = sheet container `{overflow:'hidden',
      translateY: closeY}` + chrome child `translateY: −closeY` (one shared
      value, two styles); bottom fade 120ms; bg fade 180ms; stretch −24 (100ms)
      → drop to `dropHeight = windowH + insets` (320ms); `runOnJS` unmount at 420ms.
- [ ] Kill the 500ms stale-close guard for the RN path (clean lifecycle).
- [ ] Verify side-by-side vs native toggle, frame-by-frame.

### Stage 52 — Stage-1 braindump list + entrance cascade
- [ ] `src/flow/BrainDumpList.tsx` — banner, console card (placeholder "Brain
      dump your tasks…"), section cards (subtasks, effort, settings, time,
      order, tags, notes), submit FAB — geometry from `Metrics.swift` +
      `02_SCREENS.md`.
- [ ] Entrance cascade: all blocks release simultaneously one frame after mount;
      per-block start translateY 30/30/50/70/90 → 0 on ONE spring
      {stiffness:416, damping:24.3}; transform-only.

### Stage 53 — Onboarding overlay + morph Act I (stretch)
- [ ] `src/flow/OnboardingOverlay.tsx` — white vertical gradient scrim
      (transparent@0.072 → white@0.615, expo-linear-gradient), title, "See how"
      capsule CTA; fade-in at +120ms after entrance (easeOut 300); fade-out
      easeOut 180 when morph starts.
- [ ] Act I stretch (drawDown spring {d:700, ratio:1.0}, held 1500ms):
      banner+console translateY 0→30; **console growth re-architecture** —
      sections container translateY 0→700 (pure transform) + console bg
      extension as an absolute childless leaf (height animation on the leaf
      only; fallback: pure-transform clip-slide with fixed top-cap if profiling
      shows commit cost); FAB rides the section block; scroll disabled.

### Stage 54 — Morph Acts II + III (release + landing)
- [ ] Pre-mount `RedesignedCanvas` (hidden, reconstructed frame: sheetTop=250,
      radius 36, blue bg + banner reconstruction, ghost old header) during the
      1.5s hold → swap at 1500ms is a pure opacity flip, zero React commit.
- [ ] Act II: rise 250→0 (riseSpring) + ghost header −120 + fade (same spring);
      bg blue→artwork flip at +380ms under cover; radius 36→48; hold 200ms;
      retract 0→safeTop (retractSpring).
- [ ] Act III: chrome drop −28→0 (newHeaderSpring) at retractStart+300ms; bar
      rise 280→0 (bottomBarSpring) +60ms; at +450ms placeholder cross-fade
      (opacity + letterSpacing 0.2→0.8 on leaf Texts) + focus + morphPhase→idle;
      persist `hasSeenOnboarding`.

### Stage 55 — Picker cluster jank fixes (`src/braindump/`)
- [ ] `WhenPickerCard.tsx`: fixed-intensity BlurViews cross-faded via opacity
      (kill per-frame `intensity`); date↔time accordion → pre-render both
      sections absolute, transform+opacity swap; animate only a childless
      cover leaf if a size change is truly needed.
- [ ] `MorphingShell.tsx`: glass shell → absolute childless leaf (height/radius
      spring touches only the leaf); chip + picker content pre-mounted as
      overlay siblings (opacity/scale swap — already mostly true); voice-slot
      `marginRight` → translateX of the voice button.
- [ ] Remove mid-animation setState (`setSection`/`setTime`/`setWheelKey`
      commit at boundaries), `openH`/`screenH` → shared values.
- [ ] `GlassSurface.tsx`: stop animating `shadowOpacity` (static shadow or
      opacity on a wrapper).
- [ ] Delete `RollingText.tsx` if fully superseded by the `NumericText` leaf.

### Stage 56 — Fidelity + perf pass, cleanup
- [ ] Frame-by-frame comparison vs native toggle + reference videos
      (`/Users/ilyssssha/Desktop/Text Dump Onboarding.mp4`, handoff `reference/`).
- [ ] Perf: JS thread idle during timelines; Instruments / perf monitor on
      device; 120Hz target.
- [ ] Cleanup: dead code, guards, `tasks/lessons.md` update, review section here.

## Verification

Each stage: build (`npm run ios` / Xcode), flip the debug toggle, run both
implementations back-to-back on the same device; record screen and compare
against native + reference videos. Perf stages: Xcode Instruments (Core
Animation FPS, Hangs), RN perf monitor for JS-thread idleness.

## Risks / notes

- `ObviouslyNarrow-Bold` must resolve for RN `Text` (already bundled by the app
  target — verify PostScript name).
- Placeholder `.blurReplace` approximated with opacity+letterSpacing cross-fade
  (no per-frame blur); validate look.
- expo-blur opacity cross-fade look vs native intensity ramp in the accordion.
- Keyboard rise timing (RN focus vs SwiftUI `@FocusState`) may need a 1-frame
  defer, mirroring the native `DispatchQueue.main.async` idiom.
- Monthly API spend limit was hit mid-planning (Plan subagent died) — work
  inline, no subagents, commit stage-by-stage so progress survives.
