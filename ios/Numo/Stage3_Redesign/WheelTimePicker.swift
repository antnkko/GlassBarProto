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

    // The scroll write-back lives in its OWN state, decoupled from the parent's
    // authoritative `selection` (the intended time), so the two-way
    // `.scrollPosition(id:)` can't clobber the intended value at first layout —
    // that clobber was why the picker opened off the current time with gray
    // (unmatched) digits until a scroll/AM-PM toggle. Color keys off the
    // centered row (`scrollID`); `selection` is the stable output, synced only
    // from real user scrolls once the initial centering is done.
    @State private var scrollID: Value?
    @State private var ready = false

    private var farScale: CGFloat { R.wheelFontFar / R.wheelFontCenter }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                // A plain VStack (not Lazy): the wheel has ≤12 rows, render them
                // all so the intended row is always laid out to center on.
                VStack(spacing: 0) {
                    ForEach(items, id: \.self) { item in
                        Text(label(item))
                            .font(NumoFont.obviouslyMedium(R.wheelFontCenter))
                            .foregroundStyle(item == scrollID ? NumoColor.vibrant : NumoColor.grayNight)
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
            .scrollPosition(id: $scrollID, anchor: .center)
            .scrollTargetBehavior(.viewAligned(anchor: .center))
            .scrollIndicators(.hidden)
            .frame(width: R.wheelColWidth, height: R.wheelRowHeight * CGFloat(R.wheelVisibleRows))
            .contentMargins(.vertical, R.wheelRowHeight * CGFloat(R.wheelVisibleRows - 1) / 2, for: .scrollContent)
            .onAppear { centerOnIntended(proxy) }
            .onChange(of: scrollID) { _, new in
                if ready, let value = new { selection = value }
            }
        }
    }

    /// Center the wheel on the intended time. The Time section is INSERTED with a
    /// blur-replace + spring, and the keyboard's safe-area shift relayouts the
    /// sheet — so a single early scroll lands on the wrong row and never
    /// re-asserts (that was the "opens off the current time, digits gray" bug).
    /// Re-center across the settle window: `proxy.scrollTo` forces the move even
    /// when the binding already equals the target (reliable for off-screen rows
    /// AND the 2-row AM/PM column), and `scrollID` drives the accent color. Only
    /// after it settles does scroll-driven selection (`ready`) turn on, so the
    /// re-centers can't be mistaken for user scrolls.
    private func centerOnIntended(_ proxy: ScrollViewProxy) {
        guard let target = selection else { return }
        scrollID = target
        func center() {
            var tx = Transaction(); tx.disablesAnimations = true
            withTransaction(tx) {
                proxy.scrollTo(target, anchor: .center)
                scrollID = target
            }
        }
        for delay in [0.0, 0.25, 0.5, 0.75] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: center)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { ready = true }
    }
}
