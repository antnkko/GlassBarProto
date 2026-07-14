import SwiftUI

private typealias R = Metrics.Redesign.WhenPicker

private enum Meridiem: Hashable {
    case am, pm
    var text: String { self == .am ? "AM" : "PM" }
}

/// Custom flat time wheel matching the Figma (Obviously font, blue centred item, gray
/// fade above/below, a single blue capsule band) — replaces the native `DatePicker(.wheel)`,
/// which can't take our font or recolor its selection band. Three snapping scroll columns
/// (hour 1–12, minute in 5-min steps, AM/PM), two-way bound to `selectedTime`.
/// Figma 0lzHrZXAOz9NUPNQ8gnBye · 1112:8924.
struct WheelTimePicker: View {
    @Binding var selectedTime: Date

    @State private var hour: Int?
    @State private var minute: Int?
    @State private var meridiem: Meridiem?
    /// Re-entrancy guard: while we push `selectedTime → columns`, suppress the column
    /// `→ selectedTime` write-back so the two don't ping-pong.
    @State private var isSyncingFromDate = false

    private static let minutes = Array(stride(from: 0, to: 60, by: R.wheelMinuteStep))

    init(selectedTime: Binding<Date>) {
        _selectedTime = selectedTime
        let parts = Self.decompose(selectedTime.wrappedValue)
        _hour = State(initialValue: parts.hour)
        _minute = State(initialValue: parts.minute)
        _meridiem = State(initialValue: parts.meridiem)
    }

    var body: some View {
        ZStack {
            // The one and only selection band — full width, behind the columns.
            Capsule()
                .fill(NumoColor.vibrantLight.opacity(R.wheelBandOpacity))
                .frame(height: R.wheelBandHeight)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)

            HStack(spacing: R.wheelColumnGap) {
                WheelColumn(items: Array(1...12), selection: $hour) { "\($0)" }
                WheelColumn(items: Self.minutes, selection: $minute) { String(format: "%02d", $0) }
                WheelColumn(items: [Meridiem.am, .pm], selection: $meridiem) { $0.text }
            }
        }
        .frame(height: R.wheelRowHeight * CGFloat(R.wheelVisibleRows))
        // Sync the (5-min snapped) wheel value back so the Time row label matches it.
        .onAppear { writeBack() }
        .onChange(of: selectedTime) { _, _ in syncFromDate() }
        .onChange(of: hour) { _, _ in writeBack() }
        .onChange(of: minute) { _, _ in writeBack() }
        .onChange(of: meridiem) { _, _ in writeBack() }
        .sensoryFeedback(.selection, trigger: hour)
        .sensoryFeedback(.selection, trigger: minute)
        .sensoryFeedback(.selection, trigger: meridiem)
    }

    // MARK: - Date ⇄ columns

    private static func decompose(_ date: Date) -> (hour: Int, minute: Int, meridiem: Meridiem) {
        let cal = Calendar.current
        let h24 = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        let mer: Meridiem = h24 < 12 ? .am : .pm
        let h = h24 % 12
        let h12 = h == 0 ? 12 : h
        let step = R.wheelMinuteStep
        var snapped = Int((Double(m) / Double(step)).rounded()) * step
        if snapped >= 60 { snapped = 60 - step }   // never show :60
        return (h12, snapped, mer)
    }

    private func syncFromDate() {
        let parts = Self.decompose(selectedTime)
        isSyncingFromDate = true
        if hour != parts.hour { hour = parts.hour }
        if minute != parts.minute { minute = parts.minute }
        if meridiem != parts.meridiem { meridiem = parts.meridiem }
        DispatchQueue.main.async { isSyncingFromDate = false }
    }

    private func writeBack() {
        guard !isSyncingFromDate, let h = hour, let m = minute, let mer = meridiem else { return }
        var h24 = h % 12
        if mer == .pm { h24 += 12 }
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: selectedTime)
        comps.hour = h24
        comps.minute = m
        if let d = cal.date(from: comps), d != selectedTime { selectedTime = d }
    }
}

/// One snapping scroll column. The centred row is `vibrant` (driven by `selection`); rows
/// shrink + fade with distance from centre via `.scrollTransition` (visual-effect only).
private struct WheelColumn<Value: Hashable>: View {
    let items: [Value]
    @Binding var selection: Value?
    let label: (Value) -> String

    private var farScale: CGFloat { R.wheelFontFar / R.wheelFontCenter }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(items, id: \.self) { item in
                        Text(label(item))
                            .font(NumoFont.obviouslyMedium(R.wheelFontCenter))
                            .foregroundStyle(item == selection ? NumoColor.vibrant : NumoColor.grayNight)
                            .frame(maxWidth: .infinity)
                            .frame(height: R.wheelRowHeight)
                            .id(item)
                            .scrollTransition(.interactive, axis: .vertical) { content, phase in
                                let d = min(1, abs(phase.value) / R.wheelRampSpan)
                                return content
                                    .scaleEffect(1 - (1 - farScale) * d)
                                    .opacity(1 - (1 - R.wheelOpacityFar) * d)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $selection, anchor: .center)
            .scrollTargetBehavior(.viewAligned(anchor: .center))
            .scrollIndicators(.hidden)
            .frame(width: R.wheelColWidth, height: R.wheelRowHeight * CGFloat(R.wheelVisibleRows))
            .contentMargins(.vertical, R.wheelRowHeight * CGFloat(R.wheelVisibleRows - 1) / 2, for: .scrollContent)
            // Init-time scrollPosition is dropped before first layout — center the
            // selected item explicitly once laid out.
            .onAppear {
                guard let sel = selection else { return }
                DispatchQueue.main.async { proxy.scrollTo(sel, anchor: .center) }
            }
        }
    }
}
