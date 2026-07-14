import SwiftUI

/// Font tokens mirroring `../RN Codebase/src/features/theme/typography.ts`.
/// PostScript names confirmed == bundled file basenames.
enum NumoFont {
    static func obviouslyNarrowBold(_ size: CGFloat) -> Font { .custom("ObviouslyNarrow-Bold", size: size) }
    static func obviouslySemibold(_ size: CGFloat) -> Font { .custom("Obviously-Semibold", size: size) }
    static func obviouslyMedium(_ size: CGFloat) -> Font { .custom("Obviously-Medium", size: size) }
    static func interMedium(_ size: CGFloat) -> Font { .custom("Inter-Medium", size: size) }

    // Tokens used by Stage 1
    static var titleNarrow40: Font { obviouslyNarrowBold(40) }  // input — line 46, tracking 0.2
    static var titleNarrow28: Font { obviouslyNarrowBold(28) }  // Task/Routine toggles — line 36
    static var titleWide18: Font { obviouslySemibold(18) }      // section headers — line 24
    static var titleWide16: Font { obviouslySemibold(16) }      // "Public", order label — line 22
    static var bodyWide16: Font { obviouslyMedium(16) }         // tag chips, notes — line 22
    static var caption14: Font { interMedium(14) }
}
