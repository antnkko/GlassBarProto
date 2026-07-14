import SwiftUI

/// "Private note" — header + multiline note input (placeholder visible by default).
/// Mirrors `TaskNotes.tsx`.
struct NotesSection: View {
    @State private var note = ""

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(icon: "note_icon", title: "Private note")
                    .padding(.bottom, Metrics.notesHeaderBottom)

                ZStack(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("Leave yourself a note or comment about the task")
                            .font(NumoFont.bodyWide16)
                            .foregroundStyle(NumoColor.grayNormal)
                    }
                    TextField("", text: $note, axis: .vertical)
                        .font(NumoFont.bodyWide16)
                        .foregroundStyle(NumoColor.text)
                        .tint(NumoColor.vibrant)
                }
                .padding(.leading, Metrics.notesIndent)
                .frame(minHeight: Metrics.notesMinHeight, alignment: .topLeading)
            }
        }
    }
}
