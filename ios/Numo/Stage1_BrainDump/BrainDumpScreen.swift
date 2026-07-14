import SwiftUI

/// Stage 1 — faithful reconstruction of the current brain dump screen: full scrollable form
/// on the vibrant canvas. Voice banner → console → form-section cards, with a floating submit
/// FAB. Mirrors `AddTaskScreen` + `TaskForm` (default online state, keyboard down).
struct BrainDumpScreen: View {
    var morph: Namespace.ID? = nil

    @EnvironmentObject private var flow: AppFlowCoordinator
    @State private var text = ""
    @State private var isPublic = true
    @FocusState private var inputFocused: Bool
    /// Drives the 1:1 RN "appear" animation (sections slide up). Reset whenever the
    /// screen is (re)created on `route → .brainDump`, so the entrance replays each open.
    @State private var entered = false

    /// Morph Act I (drawn bow): true while stretching AND through the release, so the
    /// stretched geometry holds as the console flies up (matched geometry) and the screen
    /// is swapped out (see `MorphChoreo`).
    private var stretching: Bool { flow.morphPhase != .idle }

    var body: some View {
        ZStack {
            NumoColor.vibrant
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Act I draw-down: banner + console pull down a touch and the
                        // console SWELLS — its growth pushes every section down uniformly
                        // (pure layout), so the sections keep their spacing and exit as
                        // one block. Smooth `drawDown` (no rebound) — keyed to the
                        // `stretching` Bool so it's untouched at release.
                        VoiceBanner()
                            .offset(y: stretching ? MorphChoreo.consolePull : 0)
                            .animation(MorphChoreo.drawDown, value: stretching)
                            .padding(.bottom, -Metrics.bannerOverlap)   // overlaps the console
                            .entranceSlide(BrainDumpEntrance.banner, active: entered)

                        ConsoleCard(
                            text: $text,
                            isPublic: isPublic,
                            inputFocus: $inputFocused,
                            onBack: { flow.goHome() },
                            onTogglePublicity: { isPublic.toggle() },
                            stretchExtraHeight: stretching ? MorphChoreo.consoleGrowth : 0
                        )
                        .offset(y: stretching ? MorphChoreo.consolePull : 0)
                        .animation(MorphChoreo.drawDown, value: stretching)
                        .padding(.top, Metrics.cardTopMargin)
                        .entranceSlide(BrainDumpEntrance.console, active: entered)

                        SubtasksSection().padding(.top, Metrics.sectionGap)
                            .entranceSlide(BrainDumpEntrance.subtasks, active: entered)
                        EffortSection().padding(.top, Metrics.sectionGap)
                            .entranceSlide(BrainDumpEntrance.settings, active: entered)
                        SettingsSection().padding(.top, Metrics.sectionGap)
                            .entranceSlide(BrainDumpEntrance.settings, active: entered)
                        TimeSection().padding(.top, Metrics.sectionGap)
                            .entranceSlide(BrainDumpEntrance.time, active: entered)
                        OrderSection().padding(.top, Metrics.sectionGap)
                            .entranceSlide(BrainDumpEntrance.time, active: entered)
                        TagsSection().padding(.top, Metrics.sectionGap)
                            .entranceSlide(BrainDumpEntrance.time, active: entered)
                        NotesSection().padding(.top, Metrics.sectionGapNotes)
                            .entranceSlide(BrainDumpEntrance.time, active: entered)
                            .id("bottomAnchor")
                    }
                    .padding(.bottom, Metrics.fabClearance)
                    // The console growth (a layout change) animates with the draw-down too.
                    .animation(MorphChoreo.drawDown, value: stretching)
                }
                .scrollDisabled(stretching)
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    // Debug-only: lets a simulator screenshot reach the lower sections.
                    if ProcessInfo.processInfo.environment["NUMO_SCROLL"] == "bottom" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation { proxy.scrollTo("bottomAnchor", anchor: .bottom) }
                        }
                    }
                }
            }
        }
        // Hidden debug trigger: triple-tap advances the stage until real triggers exist.
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture(count: 3).onEnded { flow.debugAdvance() })
        // 1:1 RN entrance: hold sections at their offsets, then release them together
        // 250 ms after appear (RN's post-nav delay). Replays each time the screen opens.
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + BrainDumpEntrance.delay) {
                withAnimation(BrainDumpEntrance.spring) { entered = true }
            }
            // Reveal the Stage 2 overlay as the slide-up is landing (overlapping its tail),
            // so the two read as one continuous sequence rather than the overlay feeling
            // postponed (a spring-completion trigger fires only after the full bouncy settle).
            DispatchQueue.main.asyncAfter(deadline: .now() + BrainDumpEntrance.overlayRevealDelay) {
                flow.showOnboardingAfterEntrance()
            }
        }
    }
}
