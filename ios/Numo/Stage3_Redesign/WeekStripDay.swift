import SwiftUI

private typealias R = Metrics.Redesign.WhenPicker

/// One day cell in the "When" picker's week strip: uppercase weekday over a day number.
/// Selected → light-blue rounded fill + blue number; today → a small blue dot below.
/// Figma 0lzHrZXAOz9NUPNQ8gnBye (Weekday component 1107:8615 / 1107:8613).
struct WeekStripDay: View {
    let date: Date
    var isSelected: Bool = false
    var isToday: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: R.cellGap) {
                Text(weekday)
                    .font(NumoFont.obviouslySemibold(R.weekdaySize))
                    .tracking(R.weekdayTracking)
                    .foregroundStyle(isSelected
                        ? NumoColor.vibrantLight
                        : NumoColor.grayNight.opacity(R.weekdayOpacity))
                Text(dayNumber)
                    .font(NumoFont.obviouslySemibold(R.daySize))
                    .foregroundStyle(isSelected ? NumoColor.vibrant : NumoColor.neutralDark)
            }
            // FLEX the cell width (no rigid `width: cellWidth` min) so the 7-cell strip always fits
            // the shell — even as it narrows on close — instead of overflowing and widening the
            // background canvas. The selection pill is capped at `cellWidth` (shrinks if tight).
            .frame(height: R.cellHeight)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: R.selectedRadius, style: .continuous)
                        .fill(NumoColor.vibrantLight.opacity(R.selectedBgOpacity))
                        .frame(maxWidth: R.cellWidth)
                }
            }
            .overlay(alignment: .bottom) {
                if isToday {
                    Circle()
                        .fill(NumoColor.vibrant)
                        .frame(width: R.todayDot, height: R.todayDot)
                        .offset(y: R.todayDotOffset)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressFadeStyle())
    }

    private var weekday: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEE"                          // "Thu"
        return String(f.string(from: date).prefix(2)).uppercased()   // → "TH"
    }

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: date))
    }
}
