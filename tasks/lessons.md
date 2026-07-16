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
