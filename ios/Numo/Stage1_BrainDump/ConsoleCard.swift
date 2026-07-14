import SwiftUI

/// UILabel wrapper that renders the placeholder with a tight paragraph line height.
private struct TightPlaceholder: UIViewRepresentable {
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 0.78
        let font = UIFont(name: "ObviouslyNarrow-Bold", size: 40) ?? UIFont.systemFont(ofSize: 40)
        let color = UIColor(NumoColor.grayNormal)

        label.attributedText = NSAttributedString(
            string: "Brain dump your\ntasks\u{2026}",
            attributes: [
                .font: font,
                .foregroundColor: color,
                .kern: Metrics.inputTracking,
                .paragraphStyle: style
            ]
        )
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {}
}

/// The white console card: header (back + publicity pill) overlaid at top, the 40pt
/// multiline input, and the freemium line. Mirrors `TaskConsole.tsx` + `Wrapper.tsx`.
struct ConsoleCard: View {
    @Binding var text: String
    var isPublic: Bool
    var inputFocus: FocusState<Bool>.Binding
    var onBack: () -> Void = {}
    var onTogglePublicity: () -> Void = {}
    /// Morph Act I: extra inner height so the white card swells downward to fill the
    /// center+bottom of the screen during the bow-stretch (see `MorphChoreo`).
    var stretchExtraHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 40pt multiline input with custom placeholder color
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    TightPlaceholder()
                }
                TextField("", text: $text, axis: .vertical)
                    .font(NumoFont.titleNarrow40)
                    .tracking(Metrics.inputTracking)
                    .foregroundStyle(NumoColor.text)
                    .tint(NumoColor.vibrant)
                    .focused(inputFocus)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > Metrics.inputMaxLength {
                            text = String(newValue.prefix(Metrics.inputMaxLength))
                        }
                    }
            }
            .frame(minHeight: Metrics.inputMinHeight, alignment: .topLeading)
            .padding(.top, Metrics.inputTopMargin)
            .padding(.bottom, Metrics.inputBottomMargin)
        }
        .padding(.bottom, stretchExtraHeight)
        .padding(Metrics.cardPadding)
        .frame(maxWidth: .infinity, minHeight: Metrics.cardMinHeight, alignment: .topLeading)
        .background(NumoColor.white)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .overlay(alignment: .top) {
            // Header — RN positions this absolutely at top 20 / sides 20.
            HStack(alignment: .center) {
                BackButton(action: onBack)
                Spacer(minLength: 0)
                PublicityPill(isPublic: isPublic, action: onTogglePublicity)
            }
            .padding(.horizontal, Metrics.headerInset)
            .padding(.top, Metrics.headerInset)
        }
    }
}
