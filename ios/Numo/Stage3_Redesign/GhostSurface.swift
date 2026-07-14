import SwiftUI

private typealias R = Metrics.Redesign

extension View {
    /// The redesign's "ghost" surface: white fill, soft grayNormal halo shadow, and a
    /// faint 2pt outer ring. Shared by the close button, publicity/tags pill, and
    /// routine/time card (the latter two by user preference — Figma gives them a
    /// heavier black-20% shadow + #F1F1F1 stroke that reads muddy next to the ghost).
    func ghostSurface<S: InsettableShape>(_ shape: S) -> some View {
        background(
            shape
                .fill(NumoColor.white)
                .shadow(color: NumoColor.grayNormal.opacity(R.ghostShadowOpacity),
                        radius: R.ghostShadowBlur / 2)
        )
        .overlay(
            shape
                .inset(by: -R.ghostRingWidth / 2)
                .stroke(NumoColor.grayNormal.opacity(R.ghostRingOpacity),
                        lineWidth: R.ghostRingWidth)
        )
    }
}
