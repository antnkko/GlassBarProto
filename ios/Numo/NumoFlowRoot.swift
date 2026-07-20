import GlassTabBar
import SwiftUI

// The braindump chrome's Liquid Glass config, injected so RedesignedScreen
// (and any donor screen) reads the same material the RN dev panel drives.
private struct NumoGlassKey: EnvironmentKey {
    static let defaultValue = GlassTabBarConfig.frozen()
}
extension EnvironmentValues {
    var numoGlass: GlassTabBarConfig {
        get { self[NumoGlassKey.self] }
        set { self[NumoGlassKey.self] = newValue }
    }
}

// Stage 41: upward event channel to RN (picker/entry/exit beats). Injected as
// an environment value so any screen in the flow can emit without threading a
// closure through every init.
private struct NumoFlowEmitKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}
extension EnvironmentValues {
    var numoFlowEmit: (String) -> Void {
        get { self[NumoFlowEmitKey.self] }
        set { self[NumoFlowEmitKey.self] = newValue }
    }
}

// The RN-hosted replacement for the donor's RootView: renders the braindump
// flow WITHOUT the SwiftUI HomeScreen (the React Native screen behind the
// transparent host plays that role). Owns the AppFlowCoordinator + the morph
// namespace, exactly like RootView did, and reports "fully closed" upward so
// the Fabric side can unmount the overlay.
//
// Modes (one immutable mode per mounted instance — RN remounts per open):
//   dumped    — the voice-dump confirmation animation demo (dev panel).
//   reset     — clears the onboarding flag and closes immediately.
// Stage 78: the braindump/onboarding native path is GONE — the RN Reanimated
// flow (src/flow) is the only braindump implementation.
struct NumoFlowRoot: View {
    let mode: String
    let onClosed: () -> Void
    private let glass: GlassTabBarConfig
    // Stage 41: live RN props (RN-owned bottom bar) + upward event channel.
    private let bridge: NumoFlowPropsBridge
    private let onEvent: (String) -> Void

    @StateObject private var flow: AppFlowCoordinator
    @Namespace private var morph

    init(mode: String, shadowOpacity: Double = 0.35, shadowRadius: Double = 0.35,
         bridge: NumoFlowPropsBridge = NumoFlowPropsBridge(),
         onEvent: @escaping (String) -> Void = { _ in },
         onClosed: @escaping () -> Void) {
        self.mode = mode
        self.onClosed = onClosed
        self.bridge = bridge
        self.onEvent = onEvent
        self.glass = .frozen(shadowOpacity: shadowOpacity, shadowRadius: shadowRadius)
        // Configure the flow BEFORE the first body evaluation: no frame ever
        // exists in the closed state and the Stage1 entrance mounts fresh
        // (calling openFromPlus in onAppear would flash an empty frame and
        // trip the closed detector).
        _flow = StateObject(wrappedValue: AppFlowCoordinator())
    }

    var body: some View {
        ZStack {
            switch mode {
            case "dumped":
                DumpedScreen(onClose: onClosed, devMode: true)
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
        .environmentObject(bridge)
        .environment(\.numoGlass, glass)
        .environment(\.numoFlowEmit, onEvent)
    }

}
