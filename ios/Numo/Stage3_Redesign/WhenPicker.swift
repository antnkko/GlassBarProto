import SwiftUI

private typealias R = Metrics.Redesign.WhenPicker

/// Which accordion section is expanded in the "When" picker.
enum WhenSection { case date, time }

// MARK: - Card (swaps the bottom bar)

/// The "When" picker card: an accordion of a **Date** row (expands a tappable week strip)
/// and a **Time** row (expands the native iOS wheel — un-stylized, per spec). Shown in
/// place of the redesign's bottom bar; rides the keyboard. One section open at a time.
/// Figma 0lzHrZXAOz9NUPNQ8gnBye (Picker · Date & time, states Date/Time).
struct WhenPicker: View {
    @Binding var section: WhenSection
    @Binding var selectedDay: Date?
    @Binding var selectedTime: Date
    /// `bare` drops this card's own clip+ghost shell so a shared container (the morph) owns
    /// one continuous shell. The shared shell clips + ghost-surfaces around this content,
    /// and (in `bare` mode) the parent drives content opacity/scale off the morph progress.
    var bare: Bool = false

    var body: some View {
        if bare {
            innerContent
        } else {
            innerContent
                // Clip the content (overflow-clip) BEFORE ghostSurface, so its 2pt ring +
                // halo render outside the clip and survive (clipping after would shave them).
                .clipShape(RoundedRectangle(cornerRadius: R.cardRadius, style: .continuous))
                .ghostSurface(RoundedRectangle(cornerRadius: R.cardRadius, style: .continuous))
        }
    }

    /// The days blur as the white Time section covers them (Time opening) and un-blur as it
    /// reveals them (Date opening) — same "appear in blur" feel as the wheel — while STILL sitting
    /// under the sliding cover. Animates on the ambient `sectionResize`. (0 = sharp/covered-only.)
    private static let coveredBlur: CGFloat = 9

    /// Two layers: the BASE (Date row + week strip) and, on top, an OPAQUE WHITE Time section
    /// that slides UP to cover the days when Time opens and DOWN to reveal them when Date opens.
    /// The cover is positioned by HIDDEN copies of the rows above it (`.hidden()` reserves the
    /// exact space — no height math); its white bg occludes the days it overlaps. The days stay
    /// sharp (`coveredBlur` 0); the wheel blur-swaps only on appear (disappear fades). Slide rides
    /// `sectionResize` (Round 26).
    private var innerContent: some View {
        ZStack(alignment: .top) {
            // BASE — Date row + week strip, ALWAYS laid out so it HOLDS its space and the white
            // Time cover slides physically OVER it (rather than into vacated space). The days
            // stay sharp (`coveredBlur` 0) — the white cover simply occludes/reveals them.
            VStack(spacing: 0) {
                row(icon: "picker_calendar", label: "Date", value: dayValueText, section: .date)
                dateBlock
                    .blur(radius: section == .date ? 0 : Self.coveredBlur)
            }

            // COVER — opaque white Time section. Hidden spacers (a hidden Date row, plus the days
            // when Date is open) push it BELOW the days (revealed); collapsing the days spacer on
            // `sectionResize` slides it UP over the days (covered). White bg is on the Time section
            // only, so the real Date row (base) shows through the transparent spacers.
            VStack(spacing: 0) {
                row(icon: "picker_calendar", label: "Date", value: dayValueText, section: .date)
                    .hidden()
                    .allowsHitTesting(false)
                if section == .date {
                    dateBlock
                        .hidden()
                        .allowsHitTesting(false)
                }
                VStack(spacing: 0) {
                    // The Time section's top line — VISIBLE in BOTH states: under the days while Date is
                    // open (top of the collapsed Time section), and (slid up with the cover on
                    // `sectionResize`) under the Date row when Time is open. It travels up, it doesn't
                    // fade — so there's always a divider under the Date row.
                    separator
                    row(icon: "picker_clock", label: "Time", value: timeValueText, section: .time)
                    if section == .time { timeBlock.transition(sectionTransition) }
                }
                .background(NumoColor.white)
            }
            .zIndex(1)
        }
        .frame(maxWidth: .infinity)
    }

    /// Date section's expandable block: divider + week strip.
    @ViewBuilder private var dateBlock: some View {
        VStack(spacing: 0) {
            separator
            WeekStrip(selectedDay: $selectedDay)
                .padding(R.stripPad)
        }
    }

    /// Time section's expandable block: divider + wheel.
    @ViewBuilder private var timeBlock: some View {
        VStack(spacing: 0) {
            separator
            WheelTimePicker(selectedTime: $selectedTime)
                .frame(maxWidth: .infinity)
                .padding(.vertical, R.wheelPadV)
        }
    }

    /// Appear blur-swaps in (same native `.blurReplace` as the publicity label, riding the ambient
    /// `sectionResize`); the disappear just FADES — no blur — and clears quicker on
    /// `sectionDisappear` so the outgoing wheel doesn't linger or smear.
    private var sectionTransition: AnyTransition {
        .asymmetric(
            insertion: AnyTransition(.blurReplace),
            removal: AnyTransition(.opacity).animation(PickerMorph.sectionDisappear)
        )
    }

    /// A "Picker text row": icon + (small label / value) + a right-chevron that fades out
    /// while its own section is expanded. The whole row toggles its section.
    private func row(icon: String, label: String, value: String, section target: WhenSection) -> some View {
        let expanded = section == target
        return Button {
            withAnimation(PickerMorph.sectionResize) { section = target }
        } label: {
            HStack(spacing: R.rowGap) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: R.rowIcon, height: R.rowIcon)
                    .foregroundStyle(NumoColor.grayNormal)
                VStack(alignment: .leading, spacing: R.rowTextGap) {
                    Text(label)
                        .font(NumoFont.obviouslyMedium(R.rowLabel))
                        .foregroundStyle(NumoColor.grayNight)
                    Text(value)
                        .font(NumoFont.obviouslySemibold(R.rowValue))
                        .foregroundStyle(NumoColor.neutralDark)
                }
                Spacer(minLength: 0)
                Image("picker_chevron")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: R.chevron, height: R.chevron)
                    .foregroundStyle(NumoColor.grayNormal)
                    .opacity(expanded ? 0 : 1)
            }
            .padding(.leading, R.rowLeading)
            .padding(.trailing, R.rowTrailing)
            .padding(.vertical, R.rowPadV)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressFadeStyle())
    }

    private var separator: some View {
        Rectangle()
            .fill(NumoColor.grayAlmost.opacity(R.sepOpacity))
            .frame(height: R.sepThickness)
            .padding(.leading, R.rowLeading)
    }

    /// "Today" when nothing (or today) is picked, else a short weekday + day ("Thu 13").
    private var dayValueText: String {
        guard let day = selectedDay, !Calendar.current.isDateInToday(day) else { return "Today" }
        let f = DateFormatter()
        f.dateFormat = "EEE d"
        return f.string(from: day)
    }

    /// e.g. "1pm" / "1:30pm".
    private var timeValueText: String {
        let f = DateFormatter()
        f.dateFormat = Calendar.current.component(.minute, from: selectedTime) == 0 ? "ha" : "h:mma"
        return f.string(from: selectedTime).lowercased()
    }
}

// MARK: - Week strip

/// A single week (Sun–Sat containing today) of tappable day cells. Defaults to today
/// highlighted (selection nil ⇒ today).
struct WeekStrip: View {
    @Binding var selectedDay: Date?

    private let days: [Date] = WeekStrip.currentWeek()

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                WeekStripDay(
                    date: day,
                    isSelected: isSelected(day),
                    isToday: Calendar.current.isDateInToday(day),
                    action: { selectedDay = day }
                )
            }
        }
    }

    private func isSelected(_ day: Date) -> Bool {
        if let sel = selectedDay { return Calendar.current.isDate(day, inSameDayAs: sel) }
        return Calendar.current.isDateInToday(day)   // nil ⇒ today is highlighted
    }

    private static func currentWeek() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)        // 1 = Sunday
        guard let start = cal.date(byAdding: .day, value: -(weekday - 1), to: today) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
}

// MARK: - Header (swaps the top chrome)

/// The "When" picker header — `Clear` pill · "When" title · blue ✓ pill. The redesign's
/// close/publicity chrome cross-fades (blur) to this while the picker is open (the swap lives in
/// `RedesignedScreen.sheet`). Title centred independently of the side buttons via a ZStack; the
/// ✓ is a Clear-width pill so the two side buttons read symmetric.
struct WhenPickerHeader: View {
    var onClear: () -> Void = {}     // Clear — reset selection + close
    var onConfirm: () -> Void = {}   // ✓ — confirm & close the picker

    var body: some View {
        ZStack {
            Text("When")
                .font(NumoFont.obviouslyNarrowBold(R.titleSize))
                .tracking(R.titleTracking)
                .foregroundStyle(NumoColor.black)

            HStack(spacing: 0) {
                Button(action: onClear) {
                    Text("Clear")
                        .font(NumoFont.obviouslySemibold(R.clearLabel))
                        .foregroundStyle(NumoColor.neutralDark)
                        .padding(.bottom, R.clearLabelLift)   // optical centre (Obviously sits low)
                        .frame(width: R.clearWidth, height: R.clearHeight)
                        .ghostSurface(Capsule())
                        .contentShape(Rectangle())   // full pill is tappable (small glyph would leave dead area)
                }
                .buttonStyle(PressFadeStyle())

                Spacer(minLength: 0)

                Button(action: onConfirm) {
                    Image("picker_checkmark")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: R.checkIcon, height: R.checkIcon)
                        .foregroundStyle(NumoColor.white)
                        .frame(width: R.clearWidth, height: R.clearHeight)   // pill, same width as Clear
                        .background(Capsule().fill(NumoColor.vibrant))
                        // Glossy inner highlight (Figma inset white glow) — clipped inside.
                        .overlay(
                            Capsule()
                                .strokeBorder(NumoColor.white.opacity(0.5), lineWidth: 4)
                                .blur(radius: 4)
                        )
                        .clipShape(Capsule())
                        // Outline ring just OUTSIDE the fill (Figma border: vibrant @75%, 2pt).
                        .overlay(
                            Capsule()
                                .inset(by: -R.checkOutline / 2)
                                .stroke(NumoColor.vibrant.opacity(R.checkOutlineOpacity), lineWidth: R.checkOutline)
                        )
                        .contentShape(Rectangle())   // full pill is tappable (small glyph would leave dead area)
                }
                .buttonStyle(PressFadeStyle())
            }
        }
        .padding(.horizontal, R.headerPadH)
        .padding(.vertical, R.headerPadV)
    }
}
