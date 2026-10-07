import AIAKit
import SwiftUI

/// The 3×3 AIA grid: ideas down the side, words across the top.
struct LabelGrid: View {
    let spec: AIASpec
    let selectedCode: String
    /// Ideas row chosen by the first keypress in the hotkey picker.
    var pendingIdeas: Int? = nil
    let onSelect: (AIALabel) -> Void

    private let shortAxis = ["Original", "Some AI", "Mostly AI"]

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow {
                Text("Ideas ↓ · Words →")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                ForEach(0..<3, id: \.self) { column in
                    Text(shortAxis[column])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help(spec.axes.words[column])
                }
            }
            ForEach(1...3, id: \.self) { ideas in
                GridRow {
                    Text(shortAxis[ideas - 1])
                        .font(.caption)
                        .foregroundStyle(pendingIdeas == ideas ? .primary : .secondary)
                        .fontWeight(pendingIdeas == ideas ? .semibold : .regular)
                        .gridColumnAlignment(.trailing)
                        .help(spec.axes.ideas[ideas - 1])
                    ForEach(1...3, id: \.self) { words in
                        if let label = spec.label(ideas: ideas, words: words) {
                            cell(label, dimmed: pendingIdeas.map { $0 != ideas } ?? false)
                        }
                    }
                }
            }
        }
    }

    private func cell(_ label: AIALabel, dimmed: Bool) -> some View {
        let selected = label.code == selectedCode
        return Button {
            onSelect(label)
        } label: {
            VStack(spacing: 1) {
                Text(label.code)
                    .font(.caption.monospacedDigit().weight(.semibold))
                Text(label.name)
                    .font(.caption2)
            }
            .foregroundStyle(Color(hex: label.color).mostReadable(of: [Color(hex: label.dark), .white]))
            .frame(width: 88, height: 40)
            .background(Color(hex: label.color), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(selected ? Color.primary : .clear, lineWidth: 2)
            }
            .opacity(dimmed ? 0.35 : 1)
        }
        .buttonStyle(.plain)
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
