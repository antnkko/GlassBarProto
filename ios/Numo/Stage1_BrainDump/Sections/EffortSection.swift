import SwiftUI

/// "Estimated effort" — header + a space-between row of four circular S/M/L/XL buttons.
/// None selected by default. Mirrors `TaskDifficulty.tsx`.
struct EffortSection: View {
    private let levels = ["S", "M", "L", "XL"]

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(icon: "difficulty_28", title: "Estimated effort")
                    .padding(.bottom, Metrics.headerBottom)

                HStack(spacing: 0) {
                    ForEach(Array(levels.enumerated()), id: \.offset) { idx, name in
                        Text(name)
                            .font(NumoFont.titleWide18)
                            .foregroundStyle(NumoColor.vibrant)
                            .frame(width: Metrics.controlCircle, height: Metrics.controlCircle)
                            .background(NumoColor.skinLight)
                            .clipShape(Circle())
                        if idx < levels.count - 1 { Spacer(minLength: 0) }
                    }
                }
            }
        }
    }
}
