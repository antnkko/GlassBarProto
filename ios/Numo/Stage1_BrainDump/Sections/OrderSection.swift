import SwiftUI

/// "Task will insert at top" — icon circle + label. Reduced vertical padding (18).
/// Mirrors `TaskOrder.tsx` (default order = top).
struct OrderSection: View {
    var body: some View {
        SectionCard(paddingV: Metrics.orderPadV) {
            HStack(spacing: 0) {
                ZStack {
                    Circle().fill(NumoColor.skinLight)
                    Image("arrow_up_28")
                        .renderingMode(.template)
                        .resizable().scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(NumoColor.vibrant)
                }
                .frame(width: Metrics.controlCircle, height: Metrics.controlCircle)

                Text("Task will insert at top")
                    .font(NumoFont.titleWide16)
                    .foregroundStyle(NumoColor.vibrant)
                    .padding(.leading, Metrics.whenContentGap)
            }
        }
    }
}
