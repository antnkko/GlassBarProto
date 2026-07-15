import CoreGraphics

/// All Stage-1 geometry, code-verified from the RN source. Single source of truth so
/// Stage 3 can interpolate. Source: `TaskConsole.tsx` / `Wrapper.tsx` / `TaskForm.tsx`.
enum Metrics {
    // Console card (Wrapper)
    static let cardRadius: CGFloat = 36
    static let cardPadding: CGFloat = 32
    static let cardMinHeight: CGFloat = 92
    static let cardTopMargin: CGFloat = 3

    // Header (absolute: top 20, sides 20)
    static let headerInset: CGFloat = 20
    static let backSize: CGFloat = 48
    static let backRadius: CGFloat = 24
    static let backIcon: CGFloat = 28

    // Publicity pill
    static let pillPadLeading: CGFloat = 16
    static let pillPadV: CGFloat = 10
    static let pillPadTrailing: CGFloat = 12
    static let pillRadius: CGFloat = 24
    static let pillIcon: CGFloat = 28
    static let pillChevron: CGFloat = 20
    static let pillGap: CGFloat = 8
    static let pillTextChevronGap: CGFloat = 2

    // Input zone
    static let inputTopMargin: CGFloat = 64
    static let inputBottomMargin: CGFloat = 36
    static let inputMinHeight: CGFloat = 120
    static let inputTracking: CGFloat = 0.2
    static let inputMaxLength: Int = 60

    // Submit FAB
    static let fabSize: CGFloat = 80
    static let fabRadius: CGFloat = 40
    static let fabInsetBottom: CGFloat = 24
    static let fabInsetTrailing: CGFloat = 24
    static let fabArrowW: CGFloat = 24
    static let fabArrowH: CGFloat = 32
    static let fabArrowStroke: CGFloat = 4

    // ── Form sections (below the console) ──
    static let sectionGap: CGFloat = 3            // marginTop between cards
    static let sectionGapNotes: CGFloat = 4
    static let headerIconGap: CGFloat = 8         // icon → title
    static let headerBottom: CGFloat = 20         // header → content (difficulty)
    static let headerBottomTight: CGFloat = 16    // header → content (tags)

    static let controlCircle: CGFloat = 56        // difficulty buttons, when-option icon circles
    static let controlCircleRadius: CGFloat = 28

    // Settings: Task/Routine toggle tiles
    static let toggleRadius: CGFloat = 24
    static let toggleBorder: CGFloat = 3
    static let togglePadLeading: CGFloat = 24
    static let togglePadTop: CGFloat = 20
    static let togglePadBottom: CGFloat = 24
    static let toggleGap: CGFloat = 8
    static let whenOptionsTop: CGFloat = 24       // toggles → when rows
    static let whenRowGap: CGFloat = 8
    static let whenContentGap: CGFloat = 16       // icon circle → label

    // Order card uses reduced vertical padding
    static let orderPadV: CGFloat = 18

    // Tags
    static let tagsIndent: CGFloat = 16
    static let chipHeight: CGFloat = 44
    static let chipRadius: CGFloat = 12
    static let chipPadH: CGFloat = 16
    static let chipBorder: CGFloat = 1
    static let chipGap: CGFloat = 22
    static let manageTop: CGFloat = 14
    static let dividerThickness: CGFloat = 1.5
    static let dividerBottom: CGFloat = 20

    // Notes
    static let notesIndent: CGFloat = 36
    static let notesMinHeight: CGFloat = 124
    static let notesHeaderBottom: CGFloat = 4

    // Voice banner
    static let bannerHeight: CGFloat = 128
    static let bannerOverlap: CGFloat = 64        // marginBottom -64
    static let bannerPadH: CGFloat = 32
    static let bannerPadTop: CGFloat = 22
    static let bannerPadBottom: CGFloat = 20

    static let fabClearance: CGFloat = 120        // scroll bottom inset under the FAB

    // ── Stage 3 redesign (Figma 1128:14564) ──
    enum Redesign {
        // White sheet over the painterly artwork
        static let sheetTopRadius: CGFloat = 48

        // Header (padding 20, space-between)
        static let headerInset: CGFloat = 20
        static let closeSize: CGFloat = 48
        static let crossIcon: CGFloat = 20
        // "Ghost" surface (close button; pill + routine/time card adopt it by user
        // preference, replacing Figma's heavier black-20% shadow + #F1F1F1 stroke):
        // blur 20 @ grayNormal 30% + 2pt outer ring @ grayNormal 13%
        static let ghostShadowBlur: CGFloat = 20
        static let ghostShadowOpacity: Double = 0.30
        static let ghostRingWidth: CGFloat = 2
        static let ghostRingOpacity: Double = 0.13

        // Publicity & tags pill
        static let pillHeight: CGFloat = 48
        static let pillPadLeading: CGFloat = 18
        static let pillPadTrailing: CGFloat = 5
        // Lone-eyes (label retired) leading: a hair more than `pillPadTrailing` so the eyes'
        // visual left inset matches the tag's right inset — the eyes glyph is wider than the
        // tag glyph, so equal pads would leave the eyes looking left-tight.
        static let pillPadRetired: CGFloat = 7.5
        // Trailing inset when the auto-tag label is outermost — a text lead-out
        // mirroring `pillPadLeading` (icon-only trailing stays `pillPadTrailing`).
        static let pillTagPadTrailing: CGFloat = 18
        static let pillPadV: CGFloat = 4
        static let pillGap: CGFloat = 3
        static let pillIcon: CGFloat = 28
        static let pillIconBox: CGFloat = 48        // icon sits centered in a 48×48 box
        static let pillLabelOverlap: CGFloat = -4   // "Public" → eyes box overlap
        static let pillDividerSize = CGSize(width: 2, height: 24)

        // Input zone
        static let inputPadH: CGFloat = 24
        static let inputTracking: CGFloat = 0.8
        static let inputLineHeight: CGFloat = 46    // ObviouslyNarrow-Bold 40

        // Bottom bar (rides the keyboard; white gradient backdrop)
        static let barPadH: CGFloat = 20
        static let barPadTop: CGFloat = 40
        static let barPadBottom: CGFloat = 20
        static let barGap: CGFloat = 16
        static let barGradientSolidStop: CGFloat = 0.27  // transparent → solid white by 27%

        // Routine & time card
        static let cardHeight: CGFloat = 82
        static let cardRadius: CGFloat = 20
        static let cardIcon: CGFloat = 24
        static let cardIconLabelGap: CGFloat = 4
        static let cardDividerSize = CGSize(width: 2, height: 32)

        // Voice button
        static let voiceSize = CGSize(width: 115, height: 80)
        static let voiceRadius: CGFloat = 20
        static let voiceBarWidth: CGFloat = 4       // 3 round bars in a 24pt box
        static let voiceBarHeights: [CGFloat] = [12, 20, 16]
        static let voiceBarSpacing: CGFloat = 4

        // ── "When" picker (Figma 0lzHrZXAOz9NUPNQ8gnBye · 1112:8825 / 1112:9033) ──
        // A mode of the redesign: header (Clear / When / ✓) swaps the top chrome, this
        // card swaps the bottom bar. Reuses `.ghostSurface` for the card + Clear pill.
        enum WhenPicker {
            static let cardRadius: CGFloat = 24        // side margins reuse `barPadH` (20)

            // Frosted backdrop over the input while the picker is open (Figma panel:
            // backdrop-blur 2 + white @ 60%). We blur the input directly (only content
            // behind the panel) and dim it with white.
            static let backdropBlur: CGFloat = 4
            static let backdropDim: Double = 0.55

            // Date / Time rows ("Picker text row")
            static let rowGap: CGFloat = 12            // icon → text
            static let rowLeading: CGFloat = 20
            static let rowTrailing: CGFloat = 20
            static let rowPadV: CGFloat = 14           // tightened so the card sits snug under the header
            static let rowTextGap: CGFloat = -3        // label → value (negative: Obviously line-boxes are tall)
            static let rowIcon: CGFloat = 28
            static let rowLabel: CGFloat = 14          // "Date"/"Time"  (Obviously-Medium)
            static let rowValue: CGFloat = 17          // "Today"/"1pm"  (Obviously-Semibold)
            static let chevron: CGFloat = 20
            static let sepThickness: CGFloat = 2       // grayAlmost @ 50%, inset left by rowLeading
            static let sepOpacity: Double = 0.5

            // Custom time wheel (Figma 1112:8924) — flat scroll wheel, blue centre, one band
            static let wheelRowHeight: CGFloat = 38       // one item's row (≈ band height)
            static let wheelVisibleRows: Int = 5          // odd → true centre; wheel height = 38*5
            static let wheelColWidth: CGFloat = 44        // each column's width (centred cluster)
            static let wheelColumnGap: CGFloat = 28       // hour | minute | AM·PM
            static let wheelFontCenter: CGFloat = 18      // centred (selected) item
            static let wheelFontFar: CGFloat = 14         // edge item
            static let wheelOpacityFar: Double = 0.4      // edge opacity (centre = 1)
            static let wheelColorThreshold: Double = 0.28 // |phase| under this ⇒ blue
            static let wheelRampSpan: Double = 0.6        // |phase| at which the far look is reached
            static let wheelMinuteStep: Int = 5           // Figma shows 5-min increments
            static let wheelPadV: CGFloat = 6             // wheel's vertical inset in the card
            // Selection band (Figma #53ACFF @ 15%, capsule, full width)
            static let wheelBandHeight: CGFloat = 38
            static let wheelBandOpacity: Double = 0.15

            // Week strip — 7 flexible cells, fixed-width selection behind each
            static let stripPad: CGFloat = 12
            static let cellWidth: CGFloat = 48
            static let cellHeight: CGFloat = 64
            static let cellGap: CGFloat = 0            // weekday → number (tight stack)
            static let weekdaySize: CGFloat = 12
            static let daySize: CGFloat = 17
            static let selectedRadius: CGFloat = 14
            static let selectedBgOpacity: Double = 0.15   // vibrantLight (#53ACFF)
            static let weekdayTracking: CGFloat = 0.36
            static let weekdayOpacity: Double = 0.60
            static let todayDot: CGFloat = 6
            static let todayDotOffset: CGFloat = 3        // pokes below the cell bottom

            // Header (Clear / When / ✓)
            static let headerPadH: CGFloat = 22
            static let headerPadV: CGFloat = 20
            static let clearHeight: CGFloat = 48
            static let clearPadH: CGFloat = 20
            static let clearWidth: CGFloat = 96        // fixed Clear-pill width; the ✓ matches it (symmetric side buttons)
            static let clearLabel: CGFloat = 17
            static let clearLabelLift: CGFloat = 5     // optical-centre lift (Obviously sits low)
            static let titleSize: CGFloat = 28
            static let titleTracking: CGFloat = 0.56
            static let checkCircle: CGFloat = 47
            static let checkIcon: CGFloat = 24         // picker_checkmark glyph (native 24, stroke 3.5)
            static let checkOutline: CGFloat = 2       // 2pt ring just outside the fill (Figma border)
            static let checkOutlineOpacity: Double = 1.0    // vibrant, full opacity
        }
    }
}
