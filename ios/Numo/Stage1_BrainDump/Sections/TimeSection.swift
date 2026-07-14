import SwiftUI

/// "Add time" — collapsed default (header only, picker hidden). Mirrors `TaskTime.tsx`.
struct TimeSection: View {
    var body: some View {
        SectionCard {
            SectionHeader(icon: "clock_icon", title: "Add time")
        }
    }
}
