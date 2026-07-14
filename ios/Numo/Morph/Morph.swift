import SwiftUI

/// Stable identities for elements that may morph between Stage 1 and the Stage 3 redesign.
/// Counterparts get wired once the redesign Figma lands.
enum MorphID: String, CaseIterable {
    case background, console, input, fab, publicityPill, backButton
}

extension View {
    /// Apply a stable morph identity when a namespace is supplied (no-op otherwise),
    /// so Stage 1 stays decoupled until Stage 3 provides the destination.
    @ViewBuilder
    func morph(_ id: MorphID, in ns: Namespace.ID?, isSource: Bool = true) -> some View {
        if let ns {
            matchedGeometryEffect(id: id.rawValue, in: ns, properties: .frame, isSource: isSource)
        } else {
            self
        }
    }
}
