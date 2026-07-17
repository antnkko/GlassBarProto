# Lessons

## 2026-07-16 — RN animation port (Stages 49–55)
- **Metro serves whatever repo it was STARTED in.** A worktree without its own
  node_modules silently resolves against the parent repo — the app then runs
  STALE code while edits appear to do nothing. Always `npm ci` in a fresh
  worktree and `lsof -ti:8081` before trusting a bundle.
- **`simctl openurl` pops a per-call confirm dialog** — undismissable
  headlessly, and it QUEUES (reappears every launch until the sim reboots).
  For scripted capture use an in-app DEV_*_AUTOPLAY constant (repo pattern).
- **Verify animations from recordings, not assumptions:** `simctl io
  recordVideo` + AVAssetImageGenerator frame dump + reading key frames catches
  real bugs (z-order over the console header, missed timelines) that "it
  compiled" never would.
- **RN 0.86: `StyleSheet.absoluteFillObject` is gone** — use explicit
  position/edges or `StyleSheet.absoluteFill` (style prop only).
- **zsh: words starting with `=` (e.g. `echo ====`) trigger equals-expansion**
  — quote them in scripts.
- **Perf rules that fixed the Stage 41–47 jank** (keep for all future RN
  animation work here): never animate expo-blur `intensity` (fixed intensity +
  opacity cross-fade); never spring layout props over subtrees (transforms, or
  a childless absolute leaf); no setState mid-timeline (shared values +
  pre-mounted states, commits only at boundaries); worklets read shared
  values, never JS-captured state.

## 2026-07-16 — Stage 57 (device feedback)
- **Never animate/park Liquid Glass behind ancestor alpha.** UIGlassEffect
  under a UIView with alpha<1 renders broken (black blobs / darkened dirty
  shadow) on device; the sim shows a harmless fallback, so recordings lie.
  Hide/spawn glass with TRANSFORMS (clip-park, off-screen park, scale-pop).
- **Never set scale:0 on views hosting native content** — the degenerate
  matrix permanently broke SwiftUI image rendering inside a Fabric leaf.
  Park by translation instead; pop from 0.9.
- **Reanimated duration-springs don't arrive:** withSequence hands off at the
  perceptual duration with the value ~1% short — over a screen-height travel
  that's visible px. Overshoot the target and gate dependent flips on the
  ACTUAL value (useAnimatedReaction), not on timers.
- **Metro's file watcher can die silently** — the bundle served contained NONE
  of the day's edits while /status said "running". Before trusting a headless
  run, grep the served bundle for a new symbol.

## 2026-07-16 — flaky ≠ fixed
Хедер/бекдроп пікера не відкривались через race у дзеркаленні RN-пропів на SwiftUI `.onChange` (перехід губиться, якщо значення виставлене до появи view). На симуляторі після переінсталяції «запрацювало», і я списав це на застарілий процес — а на пристрої в Release баг повернувся. Правило: якщо недетермінований збій зник без зрозумілого кореня — він не полагоджений; чинити треба ідемпотентною звіркою повного стану (sync від обох пропів + onAppear), а не дельта-обробниками.

## 2026-07-16 — Routine picker review corrections

1. **Позиційна логіка, переюзана з еталонного кейсу, ламається на граничних розмірах.**
   Symmetric-gap lift у BraindumpBottomBar виглядав коректно з When-карткою (~324pt, lift ≈ 0), але короткі routine-картки (202–296pt) закидало до хедера. Правило: при переюзі layout-математики прогнати її на min/max висотах нового контенту, а не тільки на висоті, для якої вона писалась. Верифікація скріншотами має явно перевіряти вертикальне закріплення відносно клавіатури, а не тільки сам контент картки.

2. **«Перенеси компонент 1:1» включає його анімацію — це acceptance, не «на потім».**
   SegmentedSwitch було портовано зі статичним thumb і заглушкою «withSpring пізніше», хоча користувач від початку просив компонент з його анімаціями. Правило: якщо у джерела (SwiftUI) є анімований стан — RN-порт має відразу їхати на сконвертованому спрінгу; статичний порт вважати незавершеним.

## 2026-07-16 — Stage 58
- **Liquid Glass adapts to sampled luminance over ~300ms.** A glass element
  that slides in from over dark content arrives dark-adapted and visibly
  normalizes. Spawning glass = stationary-glass unveil (clip-window +
  counter-translate; the pair cancels so the layer never moves) — never park
  glass over content that differs from its destination backdrop.
- **JS timers are not a beat scheduler.** setTimeout→bus→spring drifts
  (badly in Debug) and reads as jerky choreography; schedule every VISUAL
  beat with withDelay/withSequence on the UI thread; keep timers only for
  non-visual side effects (focus, persistence).
- **Effects keyed on a seq must fire on VALUE CHANGE, not deps identity** —
  an unstable callback dep re-ran the closeSeq effect after park() reset the
  guard and a stray close fired mid-open (only the double-open test caught
  it). Always test the SECOND cycle of any persistent/reset lifecycle.
- **Sim app → custom Metro port**: SIMCTL_CHILD_RCT_METRO_PORT doesn't reach
  RN 0.86; write defaults instead: `simctl spawn <sim> defaults write
  <bundleid> RCT_jsLocation "localhost:8082"`.
