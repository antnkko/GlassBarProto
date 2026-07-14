import SwiftUI

/// A standalone test screen for `SegmentedSwitch` (reached from the home admin panel). Shows the
/// live, tappable switch on the app's skin background; the ✕ dismisses via `onClose`.
/// `NUMO_SWITCH=anim` auto-cycles the selection so the slide can be captured headlessly.
struct SwitchDemoScreen: View {
    /// Dismiss handler — the ✕ calls this (presented as a full-screen cover from the admin panel).
    var onClose: () -> Void = {}
    @State private var selection = 0

    private let labels = ["Daily", "Weekly", "Monthly"]

    var body: some View {
        ZStack {
            NumoColor.skinLight.ignoresSafeArea()

            SegmentedSwitch(labels: labels, selection: $selection)
                .padding(.horizontal, 28)
        }
        .overlay(alignment: .topTrailing) {
            CloseButton { onClose() }
                .padding(.top, 20)
                .padding(.trailing, 28)
        }
        .onAppear {
            guard ProcessInfo.processInfo.environment["NUMO_SWITCH"] == "anim" else { return }
            autoCycle(from: 0)
        }
    }

    /// Debug: step the selection every second so the thumb slide can be recorded headlessly.
    private func autoCycle(from i: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let next = (i + 1) % labels.count
            withAnimation(SegSwitch.spring) { selection = next }
            autoCycle(from: next)
        }
    }
}
