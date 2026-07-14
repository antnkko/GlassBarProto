import SwiftUI

/// Native button press feedback: a subtle scale-down + slight dim on press, on a smooth spring.
/// The action fires on release and cancels on drag-off (default `Button`).
///
/// `.contentShape(Rectangle())` makes the WHOLE label frame the tap target — without it a `Button`
/// only registers taps on its content, so a small glyph in a large frame (e.g. the Clear/✓ pills)
/// leaves the empty area dead. 0.96 is the canonical native press scale.
struct PressFadeStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.96
    var pressedOpacity: Double = 0.85

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? pressedScale : 1, anchor: .center)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.66), value: configuration.isPressed)
    }
}

extension EnvironmentValues {
    /// True while a `ContentPressStyle` button is held. Lets a COMPOSITE button's content
    /// scale EACH child around its own centre (shrink in place, no drift) instead of the
    /// whole label scaling around a centre that moves as the content changes width.
    @Entry var contentPressed: Bool = false
}

/// Press feedback for COMPOSITE buttons (e.g. the publicity pill: an off-centre eyes icon +
/// a variable-width word). Publishes the held state to the label via `\.contentPressed`
/// instead of scaling the whole label — so the children can scale themselves in place and
/// nothing slides sideways. Centred single-glyph buttons keep plain `PressFadeStyle`.
struct ContentPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .environment(\.contentPressed, configuration.isPressed)
    }
}
