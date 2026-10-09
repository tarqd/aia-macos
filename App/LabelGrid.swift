import AIAKit
import SwiftUI

/// The 3×3 AIA grid: ideas down the side, words across the top.
struct LabelGrid: View {
    let spec: AIASpec
    let selectedCode: String
    /// Ideas row chosen by the first keypress in the hotkey picker.
    var pendingIdeas: Int? = nil
    /// The cell under the pointer, or nil once the pointer leaves the grid.
    var onHover: ((AIALabel?) -> Void)? = nil
    let onSelect: (AIALabel) -> Void

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(1...3, id: \.self) { words in
                    axisLabel(spec.axes.words[words - 1], position: words)
                }
            }
            ForEach(1...3, id: \.self) { ideas in
                GridRow {
                    axisLabel(spec.axes.ideas[ideas - 1], position: ideas, emphasized: pendingIdeas == ideas)
                        .multilineTextAlignment(.trailing)
                        .gridColumnAlignment(.trailing)
                    ForEach(1...3, id: \.self) { words in
                        if let label = spec.label(ideas: ideas, words: words) {
                            LabelCell(
                                label: label,
                                selected: label.code == selectedCode,
                                dimmed: pendingIdeas.map { $0 != ideas } ?? false
                            ) { onSelect(label) }
                            .onHover { if $0 { onHover?(label) } }
                        }
                    }
                }
            }
        }
        // Clear only when leaving the whole grid, so the gaps between cells don't flicker.
        .onHover { if !$0 { onHover?(nil) } }
    }

    /// "Mostly AI ideas" → "Mostly AI\nideas", so headers wrap evenly. The middle ("Some AI")
    /// header is implied by its position, so it only appears while that row is being picked.
    private func axisLabel(_ text: String, position: Int, emphasized: Bool = false) -> some View {
        let parts = text.split(separator: " ")
        return Text("\(parts.dropLast().joined(separator: " "))\n\(parts.last ?? "")")
            .font(.caption2)
            .foregroundStyle(emphasized ? .primary : .secondary)
            .fontWeight(emphasized ? .semibold : .regular)
            .lineLimit(2)
            .fixedSize()
            .opacity(position == 2 && !emphasized ? 0 : 1)
    }
}

private struct LabelCell: View {
    let label: AIALabel
    let selected: Bool
    let dimmed: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        let fill = Color(hex: selected ? label.color : label.tint)
        Button(action: action) {
            VStack(spacing: 0) {
                Text(label.code)
                    .font(.caption2.monospacedDigit())
                    .opacity(0.75)
                Text(label.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(fill.mostReadable(of: selected ? [Color(white: 0.12), .white] : [Color(hex: label.dark), .white]))
            // The badge below names the selection, so cells stay quiet until hovered.
            .opacity(hovering ? 1 : 0)
            .frame(width: 64, height: 64)
            .background(fill.opacity(selected || hovering ? 1 : 0.55), in: .rect(cornerRadius: 12))
            .shadow(color: .black.opacity(selected ? 0.18 : 0), radius: 3, y: 1)
            .scaleEffect(selected ? 1.04 : 1)
            .opacity(dimmed ? 0.3 : 1)
            .animation(.snappy(duration: 0.15), value: selected)
            .animation(.snappy(duration: 0.15), value: hovering)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .pointerStyle(.link)
        .onHover { hovering = $0 }
        .help("\(label.summary) \(label.description)")
        .accessibilityLabel("AIA \(label.code), \(label.name). \(label.summary)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The finished label as it will appear in a document.
struct BadgePreview: View {
    let snippets: Snippets

    var body: some View {
        let label = snippets.label, options = snippets.options
        if options.size == .textLine {
            HStack(spacing: 6) {
                if let icon = BadgeArtwork.icon(code: label.code, style: options.style) {
                    Image(nsImage: icon).resizable().frame(width: 16, height: 16)
                }
                Text("\(Text("\(snippets.heading).").bold()) \(label.summary)")
            }
        } else if let image = BadgeArtwork.image(code: label.code, size: options.size, style: options.style) {
            Image(nsImage: image)
        }
    }
}
