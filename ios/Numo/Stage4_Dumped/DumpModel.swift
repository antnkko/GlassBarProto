import SwiftUI

/// The three kinds of item a voice dump can parse into. Each kind maps to an RN skin
/// "family" that colors the row: task → blueRibbon, routine → slack, note → buttercup.
enum DumpKind {
    case task, routine, note

    /// Title / body text color ("vibrant dark" of the family).
    var titleColor: Color {
        switch self {
        case .task:    return NumoColor.vibrantDark
        case .routine: return NumoColor.slackDark
        case .note:    return NumoColor.buttercupDark
        }
    }

    /// Leading-glyph color — the family's brighter "vibrant" (rendered faintly, see
    /// `Metrics.Dumped.glyphOpacity`). Distinct from `titleColor`: the Figma checkbox/repeat/
    /// note glyphs are a light *vibrant* tint, not the dark title color.
    var glyphColor: Color {
        switch self {
        case .task:    return NumoColor.vibrant          // #0468FF
        case .routine: return NumoColor.slackVibrant     // #7636A2
        case .note:    return NumoColor.buttercupVibrant // #CA8700
        }
    }

    /// When-tag (speech bubble) accent ("highlight" of the family). Notes have none.
    var whenColor: Color {
        switch self {
        case .task:    return NumoColor.highlight       // orange
        case .routine: return NumoColor.slackHighlight  // green
        case .note:    return NumoColor.buttercupDark
        }
    }
}

/// One parsed line of a dump. `title` carries task/routine names; `body` carries note prose.
struct DumpEntry: Identifiable {
    let id = UUID()
    var kind: DumpKind
    var title: String = ""
    var body: String? = nil          // note text (longer, gets the bottom-fade mask)
    var tagLabel: String? = nil      // e.g. "House" / "Household"
    var tagCounter: String? = nil    // e.g. "+3"
    var when: String? = nil          // single-line date, e.g. "Tomorrow" (no time)

    /// The three sample items from the Figma frame (3071:5895).
    static let sample: [DumpEntry] = [
        DumpEntry(kind: .task, title: "Post office",
                  tagLabel: "House", tagCounter: "+3",
                  when: "Tomorrow"),
        DumpEntry(kind: .routine, title: "Gym sesh",
                  tagLabel: "Household",
                  when: "Tomorrow"),
        // Two explicit lines (Figma renders the note as two paragraphs); the long second
        // line overflows and fades out on the right.
        DumpEntry(kind: .note,
                  body: "It feels a little surreal\nhonestly, like it's been building for a while and now it's actually a thing"),
    ]
}
