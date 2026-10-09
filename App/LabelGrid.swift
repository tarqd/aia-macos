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
        Grid(horizontalSpacing: 5, verticalSpacing: 5) {
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(1...3, id: \.self) { words in
                    // Headers are wider than a cell: overlay them, starting at the cell's
                    // leading edge, so they overhang without stretching the column.
                    Color.clear
                        .frame(height: 14)
                        .overlay(alignment: .leading) { axisLabel(Self.wordsAxis[words - 1], position: words) }
                        .gridCellUnsizedAxes(.horizontal)
                }
            }
            ForEach(1...3, id: \.self) { ideas in
                GridRow {
                    axisLabel(Self.ideasAxis[ideas - 1], position: ideas, emphasized: pendingIdeas == ideas)
                        // Line the label up with the top of its row of cells.
                        .frame(height: LabelCell.side, alignment: .top)
                        .gridColumnAlignment(.leading)
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

    /// Shorter than the spec's axis names ("Original writing", "Mostly AI writing"), which
    /// the info panel and badge spell out in full.
    private static let wordsAxis = ["Human writing", "Some AI writing", "AI writing"]
    private static let ideasAxis = ["Human ideas", "Some AI ideas", "AI ideas"]

    /// The middle ("Some AI") header is implied by its position, so it only appears while that
    /// row is being picked.
    private func axisLabel(_ text: String, position: Int, emphasized: Bool = false) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(emphasized ? .primary : .secondary)
            .fontWeight(emphasized ? .semibold : .regular)
            .lineLimit(1)
            .fixedSize()
            .opacity(position == 2 && !emphasized ? 0 : 1)
    }
}

private struct LabelCell: View {
    let label: AIALabel
    let selected: Bool
    let dimmed: Bool
    let action: () -> Void

    static let side: CGFloat = 44

    @State private var hovering = false

    var body: some View {
        let fill = Color(hex: selected ? label.color : label.tint)
        Button(action: action) {
            // The panel beside the grid names the hovered or selected label, so cells are color only.
            RoundedRectangle(cornerRadius: 9)
                .fill(fill.opacity(selected || hovering ? 1 : 0.55))
                .frame(width: Self.side, height: Self.side)
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
