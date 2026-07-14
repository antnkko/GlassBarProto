import SwiftUI
import UIKit

private typealias D = Metrics.Dumped

/// "Dumped ⚡" — the task-confirmation screen shown after a voice dump (Figma 3071:5895).
/// Static UI: lists the parsed task / routine / note items in one card, with a ✕ to
/// dismiss and the blue ↑ to commit. Per-item colors come from `DumpKind`.
struct DumpedScreen: View {
    /// Dismiss handler — the ✕ calls this. (Ported as a self-contained demo: presented as a
    /// full-screen cover from the admin panel, so it dismisses the cover rather than touching flow.)
    var onClose: () -> Void = {}
    /// Prototype-only: shows the in-screen dev panel (restart + live tuning). The admin demo passes `true`.
    var devMode: Bool = false
    private let entries = DumpEntry.sample

    /// Loading entrance: `appeared` drives ✕/card/items. `titleText` ("" → "Dumping" → "Dumped") drives the
    /// title's native `.contentTransition(.numericText())` — each string change animates via the OS transition.
    @State private var appeared = false
    @State private var titleText = ""
    @State private var started = false
    @State private var morphed = false          // entrance (bounce renderer) → morph (numericText) hand-off
    @State private var entranceTime: Double = 0  // drives the per-glyph LetterBounceRenderer
    @State private var loading = true            // "Dumping" in-progress: FAB spinner + "..." dots (→ false at morph)
    @State private var titleTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Live-tunable title-animation params (seeded from `DumpedEntrance`; driven by the dev panel).
    @State private var letterStep = DumpedEntrance.letterStep
    @State private var springResponse = DumpedEntrance.titleResponse
    @State private var springDamping = DumpedEntrance.titleDamping
    @State private var morphDelay = DumpedEntrance.morphDelay
    @State private var showDevPanel = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .center, spacing: 0) {
                header
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, D.headerLeading)
                    .padding(.top, D.headerTopFromSafe)
                    .padding(.bottom, D.headerBottom)

                listCard
                    .reveal(appeared, delay: DumpedEntrance.cardDelay,
                            blur: 0, slide: DumpedEntrance.cardSlide)
            }
            .frame(maxWidth: .infinity)
            // Bottom inset so the last row can scroll clear of the fixed FAB.
            .padding(.bottom, D.fabBottom + D.fabSize + D.fabClearance)
        }
        .background(NumoColor.skinLight.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            CloseButton { onClose() }
                .closeFly(appeared, delay: DumpedEntrance.closeDelay)
                .padding(.top, D.closeTopFromSafe)
                .padding(.trailing, D.closeTrailing)
        }
        .overlay(alignment: .bottom) {
            DumpedFAB(action: onClose, loading: loading)
                .padding(.bottom, D.fabBottom)
                .reveal(appeared, delay: DumpedEntrance.chromeDelay, blur: 0, slide: 0)
        }
        .overlay(alignment: .bottomLeading) {
            if devMode {
                DumpedDevPanel(isOpen: $showDevPanel,
                               letterStep: $letterStep, response: $springResponse,
                               damping: $springDamping, morphDelay: $morphDelay,
                               onRestart: { play(initial: false) })
            }
        }
        .onAppear {
            guard !started else { return }
            started = true
            play(initial: true)
        }
        .onDisappear { titleTask?.cancel() }
    }

    /// Plays the title sequence — letter-by-letter entrance ("" → "Dumping") then morph → "Dumped" — reading
    /// the live tuning params. Cancellable so the dev panel's Restart can replay it; `initial` keeps the first
    /// play's background pause, while a restart skips it for fast iteration.
    private func play(initial: Bool) {
        titleTask?.cancel()
        appeared = false
        morphed = false
        loading = true          // FAB spinner during the loading hold (→ arrow at the morph)
        entranceTime = 0
        titleText = "Dumping"   // the entrance renderer staggers it in; after the hand-off numericText shows it
        titleTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.03))                                       // let the reset register
            try? await Task.sleep(for: .seconds(initial ? DumpedEntrance.startDelay : 0.1))  // restart skips the pause
            if Task.isCancelled { return }
            appeared = true
            try? await Task.sleep(for: .seconds(DumpedEntrance.titleStart))
            if reduceMotion {
                morphed = true   // skip the per-letter bounce; numericText just shows "Dumping"
            } else {
                // Each glyph rolls + bounces in independently (LetterBounceRenderer); one clock, no interruption.
                let total = Double("Dumping".count - 1) * letterStep + DumpedEntrance.entranceSettle
                withAnimation(.linear(duration: total)) { entranceTime = total }
                try? await Task.sleep(for: .seconds(total))
                if Task.isCancelled { return }
                morphed = true   // hand off to numericText (settled "Dumping" — invisible swap)
            }
            // Give the numericText title one frame at "Dumping" so the FIRST dot is an observed change (rolls in
            // like the others) — without this, `morphed = true` and the first dot coalesce and dot 1 just spawns.
            try? await Task.sleep(for: .seconds(0.06))
            if Task.isCancelled { return }
            // "loading" hold: cycle "..." as in-text period glyphs via numericText (prefix "Dumping" stays static).
            let base = "Dumping"
            if reduceMotion {
                titleText = base + "..."
                try? await Task.sleep(for: .seconds(morphDelay))
            } else {
                // Triangle: dot count 1→2→3→2→1→0 — dots roll IN 1,2,3 then OUT 3,2,1 (all gone), then repeat.
                // Each step adds/removes exactly one trailing ".", so every dot (incl. the first) rolls identically.
                let cycle = [".", "..", "...", "..", ".", ""]
                let cycles = max(1, Int((morphDelay / (DumpedEntrance.dotStep * Double(cycle.count))).rounded()))
                for _ in 0..<cycles {
                    for s in cycle {
                        if Task.isCancelled { return }
                        titleText = base + s
                        try? await Task.sleep(for: .seconds(DumpedEntrance.dotStep))
                    }
                }
                // ends on "Dumping" (no dots) → clean morph
            }
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.25)) { loading = false }   // FAB → arrow
            titleText = "Dumped"   // numericText morph (tail rolls/bounces)
        }
    }

    /// Title — two phases sharing `.titleStyle()` so the hand-off is invisible: (1) ENTRANCE — a per-glyph
    /// `LetterBounceRenderer` rolls each letter up and BOUNCES it in independently (every letter bounces, not
    /// just the last); (2) MORPH — once `morphed`, the stable numericText `Text` rolls "Dumping" → "Dumped"
    /// (changed tail only). Overlaid on a hidden UILabel that reserves the exact 46pt height (card never shifts).
    private var header: some View {
        DumpTitleLabel().fixedSize()
            .opacity(0)
            .overlay(alignment: .leading) {
                ZStack(alignment: .leading) {
                    if morphed {
                        Text(titleText)               // "Dumping" → cycles "..." dots → "Dumped" (numericText)
                            .titleStyle()
                            .contentTransition(reduceMotion ? .opacity : .numericText())
                            .animation(reduceMotion ? .easeInOut(duration: 0.25)
                                                    : .spring(response: springResponse, dampingFraction: springDamping),
                                       value: titleText)
                    } else {
                        Text(titleText)               // == "Dumping" during the entrance
                            .titleStyle()
                            .textRenderer(LetterBounceRenderer(elapsedTime: entranceTime, step: letterStep,
                                                               slide: DumpedEntrance.bounceSlide,
                                                               response: springResponse, damping: springDamping))
                    }
                }
                .offset(y: -DumpedEntrance.titleLift)
            }
    }

    private var listCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                let base = DumpedEntrance.itemsStart + Double(index) * DumpedEntrance.itemStride
                DumpItem(entry: entry, appeared: appeared, baseDelay: base)
                if index < entries.count - 1 {
                    DashedSeparator(appeared: appeared, delay: base + DumpedEntrance.sepOffset)
                }
            }
        }
        .frame(width: D.cardWidth)
        .background(NumoColor.white)
        .clipShape(RoundedRectangle(cornerRadius: D.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: D.cardRadius, style: .continuous)
                .stroke(NumoColor.vibrantDark.opacity(D.cardBorderOpacity), lineWidth: 1)
        )
        .shadow(color: NumoColor.vibrantDark.opacity(D.cardShadowOpacity),
                radius: D.cardShadowBlur, x: 0, y: D.cardShadowY)
    }
}

/// Inset dashed rule between rows (Figma 3071:5901).
struct DashedSeparator: View {
    var appeared: Bool = true
    var delay: Double = 0

    var body: some View {
        DumpHLine()
            .stroke(NumoColor.grayNormal.opacity(D.sepColorOpacity),
                    style: StrokeStyle(lineWidth: D.sepThickness, dash: D.sepDash))
            .frame(width: D.sepWidth, height: D.sepThickness)
            .reveal(appeared, delay: delay)
    }
}

struct DumpHLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return p
    }
}

/// "Dumped" title via UILabel — a fixed 46pt line height removes the Obviously font's loose top
/// leading so the glyph seats at the Figma position (same trick as `OverlayTitleLabel`).
private struct DumpTitleLabel: UIViewRepresentable {
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = D.titleSize
        style.maximumLineHeight = D.titleSize
        let font = UIFont(name: "ObviouslyNarrow-Bold", size: D.titleSize)
            ?? .systemFont(ofSize: D.titleSize, weight: .bold)
        label.attributedText = NSAttributedString(string: "Dumped", attributes: [
            .font: font,
            .foregroundColor: UIColor(NumoColor.vibrantDark),
            .kern: D.titleTracking,
            .paragraphStyle: style,
        ])
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {}
}

// MARK: - Dev panel (prototype-only)

/// In-screen tuning panel for the title animation: a toggle (bottom-leading) that expands a translucent
/// card with **Restart** + sliders. Anchored low so the title stays visible while tuning. Gated by `devMode`.
private struct DumpedDevPanel: View {
    @Binding var isOpen: Bool
    @Binding var letterStep: Double
    @Binding var response: Double
    @Binding var damping: Double
    @Binding var morphDelay: Double
    var onRestart: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isOpen {
                panel.transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { isOpen.toggle() }
            } label: {
                Image(systemName: isOpen ? "xmark" : "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.black.opacity(0.55)))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 20)
        .padding(.bottom, 28)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Title animation").font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: onRestart) {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            tuner("Letter step", $letterStep, 0...0.20, "%.3fs")
            tuner("Response", $response, 0.1...0.8, "%.2f")
            tuner("Damping", $damping, 0.3...1.0, "%.2f")
            tuner("Hold (loading)", $morphDelay, 0.3...4.0, "%.2fs")
        }
        .padding(14)
        .frame(width: 300, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.15)))
    }

    private func tuner(_ label: String, _ value: Binding<Double>,
                       _ range: ClosedRange<Double>, _ fmt: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.system(size: 12, weight: .medium))
                Spacer()
                Text(String(format: fmt, value.wrappedValue))
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}
