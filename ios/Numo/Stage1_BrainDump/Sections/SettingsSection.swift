import SwiftUI

/// Task/Routine toggle tiles + the "when" option rows (Today selected by default).
/// Mirrors `TaskSettings.tsx` (NormalTaskSelectOptions).
struct SettingsSection: View {
    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Metrics.toggleGap) {
                    TaskTypeToggle(icon: "task_big", label: "Task", selected: true)
                    TaskTypeToggle(icon: "repeat_icon", label: "Routine", selected: false)
                }

                VStack(spacing: Metrics.whenRowGap) {
                    WhenOptionRow(icon: "star_calendar", label: "Today", selected: true)
                    WhenOptionRow(icon: "calendar_icon", label: "Tomorrow", selected: false)
                    WhenOptionRow(icon: "arrows_right", label: "Select date", selected: false)
                    WhenOptionRow(icon: "backlog_icon", label: "Someday / Backlog", selected: false)
                }
                .padding(.top, Metrics.whenOptionsTop)
            }
        }
    }
}

/// Big "Task" / "Routine" tile — selected fills vibrant; unselected is a gray-bordered outline.
private struct TaskTypeToggle: View {
    var icon: String
    var label: String
    var selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(icon)
                .renderingMode(.template)
                .resizable().scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(selected ? Color.white : NumoColor.grayNormal)
            Text(label)
                .font(NumoFont.titleNarrow28)
                .foregroundStyle(selected ? Color.white : NumoColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Metrics.togglePadLeading)
        .padding(.top, Metrics.togglePadTop)
        .padding(.bottom, Metrics.togglePadBottom)
        .background(selected ? NumoColor.vibrant : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.toggleRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.toggleRadius, style: .continuous)
                .stroke(selected ? NumoColor.vibrant : NumoColor.grayAlmost, lineWidth: Metrics.toggleBorder)
        )
        .shadow(color: selected ? NumoColor.black.opacity(0.15) : .clear, radius: 6, x: 0, y: 4)
    }
}

/// A "when" row: 56pt icon circle + label (+ check when selected).
private struct WhenOptionRow: View {
    var icon: String
    var label: String
    var selected: Bool

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Circle().fill(selected ? NumoColor.vibrant : NumoColor.skinLight)
                Image(icon)
                    .renderingMode(.template)
                    .resizable().scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(selected ? Color.white : NumoColor.vibrant)
            }
            .frame(width: Metrics.controlCircle, height: Metrics.controlCircle)

            HStack(spacing: Metrics.headerIconGap) {
                Text(label)
                    .font(NumoFont.titleWide18)
                    .foregroundStyle(selected ? NumoColor.vibrant : NumoColor.text)
                if selected {
                    Image("check_icon")
                        .renderingMode(.template)
                        .resizable().scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(NumoColor.vibrant)
                }
            }
            .padding(.leading, Metrics.whenContentGap)

            Spacer(minLength: 0)
        }
    }
}
