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

    private static let spacing: CGFloat = 5
    private static let gridSide = LabelCell.side * 3 + spacing * 2

    var body: some View {
        // Chart-style axes: the person icon is the shared human origin, and each arrow points
        // toward more AI.
        Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 6) {
            GridRow {
                axisIcon("person.fill", label: "Human")
                AxisArrow(title: "writing", axis: .horizontal)
                    .frame(width: Self.gridSide)
            }
            GridRow {
                AxisArrow(title: "ideas", axis: .vertical, emphasized: pendingIdeas != nil)
                    .frame(height: Self.gridSide)
                cells
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ideas from human to AI, down; writing from human to AI, across")
    }

    private var cells: some View {
        Grid(horizontalSpacing: Self.spacing, verticalSpacing: Self.spacing) {
            ForEach(1...3, id: \.self) { ideas in
                GridRow {
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

    private func axisIcon(_ systemName: String, label: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .fixedSize()
            .help(label)
            .accessibilityLabel(label)
    }
}

/// A continuous axis line with an arrowhead pointing toward more AI, named like a chart axis:
/// above the line when horizontal, rotated alongside it when vertical.
private struct AxisArrow: View {
    let title: String
    let axis: Axis
    var emphasized = false

    var body: some View {
        let layout = axis == .horizontal ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        layout {
            Rectangle()
                .fill(.tertiary)
                .frame(width: axis == .vertical ? 1 : nil, height: axis == .horizontal ? 1 : nil)
            Image(systemName: axis == .horizontal ? "arrowtriangle.right.fill" : "arrowtriangle.down.fill")
                .font(.system(size: 6))
                .foregroundStyle(.tertiary)
                .padding(axis == .horizontal ? .leading : .top, -2)
        }
        .overlay {
            let text = Text(title)
                .font(.caption2)
                .foregroundStyle(emphasized ? .secondary : .tertiary)
                .fixedSize()
            if axis == .horizontal {
                text.offset(y: -8)
            } else {
                text.rotationEffect(.degrees(-90)).offset(x: -8)
            }
        }
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
