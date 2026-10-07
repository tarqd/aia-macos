import AIAKit
import Observation
import SwiftUI

/// The selected label and snippet options, shared by the menu bar, hotkey picker, and settings.
@MainActor @Observable
final class AppModel {
    static let shared = AppModel()

    let spec = AIASpec.bundled

    var selectedCode: String {
        didSet { defaults.set(selectedCode, forKey: Keys.selectedCode) }
    }

    var options: SnippetOptions {
        didSet { defaults.set(try? JSONEncoder().encode(options), forKey: Keys.options) }
    }

    /// The label whose copy confirmation is showing in the menu bar window.
    private(set) var justCopied: String?

    var selectedLabel: AIALabel {
        spec.label(code: selectedCode) ?? spec.codes[0]
    }

    private let defaults = UserDefaults.standard

    private init() {
        selectedCode = defaults.string(forKey: Keys.selectedCode) ?? "1x1"
        options = defaults.data(forKey: Keys.options)
            .flatMap { try? JSONDecoder().decode(SnippetOptions.self, from: $0) } ?? SnippetOptions()
    }

    func snippets(for label: AIALabel) -> Snippets {
        Snippets(label: label, options: options, spec: spec)
    }

    func copy(_ label: AIALabel, as kind: ClipKind, announce: Bool = false) {
        LabelClip.copy(snippets(for: label), as: kind)
        selectedCode = label.code
        justCopied = label.code
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if justCopied == label.code { justCopied = nil }
        }
        if announce {
            Toast.show("Copied AIA \(label.code) · \(label.name)", detail: "Press ⌘V to paste")
        }
    }

    func copyPageHead(_ label: AIALabel) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippets(for: label).pageHead, forType: .string)
        selectedCode = label.code
    }

    private enum Keys {
        static let selectedCode = "selectedCode"
        static let options = "snippetOptions"
    }
}

extension Color {
    /// `#RRGGBB` from the spec.
    init(hex: String) {
        let value = UInt64(hex.trimmingPrefix("#"), radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    /// Whichever of `candidates` has the highest WCAG contrast against this color.
    func mostReadable(of candidates: [Color]) -> Color {
        let background = luminance
        return candidates.max { contrast($0.luminance, background) < contrast($1.luminance, background) } ?? .primary
    }

    private var luminance: CGFloat {
        let rgb = NSColor(self).usingColorSpace(.sRGB) ?? .black
        func linear(_ c: CGFloat) -> CGFloat { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(rgb.redComponent) + 0.7152 * linear(rgb.greenComponent) + 0.0722 * linear(rgb.blueComponent)
    }

    private func contrast(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}
