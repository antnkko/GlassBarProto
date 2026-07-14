import SwiftUI

/// "Add subtasks" — collapsed default (header only). Mirrors `TaskSubtasks.tsx`.
struct SubtasksSection: View {
    var body: some View {
        SectionCard {
            SectionHeader(icon: "subtasks_arrows", title: "Add subtasks")
        }
    }
}
