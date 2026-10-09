import AIAKit
import SwiftUI

/// Four small bars drawn to each badge size's proportions. The current size is solid and
/// the others stay faint until the badge area is hovered.
struct SizeStrip: View {
    @Binding var size: BadgeSize
    /// Whether the badge card or the strip is under the pointer.
    let emphasized: Bool

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(BadgeSize.allCases, id: \.self) { option in
                Button { size = option } label: {
                    Capsule()
                        .fill(.primary)
                        .frame(width: option.glyph.width, height: option.glyph.height)
                        .opacity(opacity(for: option))
                        .frame(width: option.glyph.width + 8, height: 14)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .help(option.displayName)
                .accessibilityLabel(option.displayName)
                .accessibilityAddTraits(option == size ? .isSelected : [])
            }
        }
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: emphasized || hovering)
        .animation(.snappy(duration: 0.15), value: size)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Label size")
    }

    private func opacity(for option: BadgeSize) -> Double {
        if option == size { return 0.75 }
        return emphasized || hovering ? 0.35 : 0.15
    }
}

private extension BadgeSize {
    /// Roughly the badge's aspect ratio at strip scale.
    var glyph: CGSize {
        switch self {
        case .wide: CGSize(width: 34, height: 6)
        case .medium: CGSize(width: 17, height: 6)
        case .compact: CGSize(width: 13, height: 4)
        case .textLine: CGSize(width: 22, height: 2)
        }
    }
}

extension BadgeSize {
    /// The next or previous size, clamped at the ends.
    func stepped(by offset: Int) -> BadgeSize {
        let all = Self.allCases
        let index = all.firstIndex(of: self)! + offset
        return all[min(max(index, all.startIndex), all.index(before: all.endIndex))]
    }
}
