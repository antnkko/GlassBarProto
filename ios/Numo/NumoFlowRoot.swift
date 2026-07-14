import SwiftUI

// The RN-hosted replacement for the donor's RootView: renders the braindump
// flow WITHOUT the SwiftUI HomeScreen (the React Native screen behind the
// transparent host plays that role). Owns the AppFlowCoordinator + the morph
// namespace, exactly like RootView did, and reports "fully closed" upward so
// the Fabric side can unmount the overlay.
//
// Modes (one immutable mode per mounted instance — RN remounts per open):
//   braindump — the real "+" flow: first run plays Stage1 + onboarding +
//               morph; afterwards the direct slide-up of the redesign.
//   dumped    — the voice-dump confirmation animation demo (dev panel).
//   switch    — the segmented-switch animation demo (dev panel).
//   reset     — clears the onboarding flag and closes immediately.
struct NumoFlowRoot: View {
    let mode: String
    let onClosed: () -> Void

    @StateObject private var flow: AppFlowCoordinator
    @Namespace private var morph
    // The closed-report latch: only report after the flow has actually been
    // open — the coordinator's INITIAL state already matches the closed
    // predicate, so an unlatched observer would close the overlay at mount.
    @State private var wasOpen = false

    init(mode: String, onClosed: @escaping () -> Void) {
        self.mode = mode
        self.onClosed = onClosed
        // Configure the flow BEFORE the first body evaluation: no frame ever
        // exists in the closed state and the Stage1 entrance mounts fresh
        // (calling openFromPlus in onAppear would flash an empty frame and
        // trip the closed detector).
        let coordinator = AppFlowCoordinator()
        if mode == "braindump" {
            coordinator.openFromPlus()
        }
        _flow = StateObject(wrappedValue: coordinator)
        // The flow is opened synchronously above, so isOpen never TRANSITIONS
        // to true — onChange would never latch. Start latched instead.
        _wasOpen = State(initialValue: mode == "braindump")
    }

    var body: some View {
        ZStack {
            switch mode {
            case "braindump":
                brainDumpFlow
            case "dumped":
                DumpedScreen(onClose: onClosed, devMode: true)
            case "switch":
                SwitchDemoScreen(onClose: onClosed)
            default:
                Color.clear.onAppear {
                    if mode == "reset" {
                        UserDefaults.standard.set(false, forKey: "numo.hasSeenOnboarding")
                    }
                    onClosed()
                }
            }
        }
        .environmentObject(flow)
    }

    // The donor RootView's braindump portions, verbatim minus HomeScreen:
    // route == .home with directOpen == false simply renders nothing — the
    // RN screen behind the transparent host IS home.
    @ViewBuilder
    private var brainDumpFlow: some View {
        ZStack {
            if flow.route == .brainDump {
                brainDumpStack
                    .transition(.opacity)
            }

            if flow.directOpen {
                RedesignedScreen(morph: morph, viaMorph: false, viaSlideUp: true)
                    .transition(.identity)
                    .zIndex(2)
            }
        }
        .onChange(of: isOpen) { _, open in
            if open {
                wasOpen = true
            } else if wasOpen {
                // Let the donor's goHome() fade (0.25s ease-out) finish before
                // the Fabric side tears the hosting view down.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onClosed() }
            }
        }
    }

    private var isOpen: Bool {
        flow.route == .brainDump || flow.directOpen
    }

    // The donor RootView's Stage-1 base + morph-stage overlays, verbatim.
    @ViewBuilder
    private var brainDumpStack: some View {
        ZStack {
            if flow.stage == .redesigned {
                RedesignedScreen(morph: morph, viaMorph: flow.morphPhase == .released)
                    .transition(.identity)
                    .zIndex(1)
            } else {
                BrainDumpScreen(morph: morph)
                    .transition(.identity)
                    .zIndex(0)
            }

            if flow.stage == .onboarding {
                OnboardingOverlay()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}
