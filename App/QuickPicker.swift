import AIAKit
import AppKit
import SwiftUI

/// The hotkey picker: a floating panel that takes keystrokes without activating the app,
/// so focus is still in the user's document when it closes.
@MainActor
final class QuickPicker {
    static let shared = QuickPicker()

    private var panel: PickerPanel?

    func toggle() {
        if let panel, panel.isVisible { close() } else { show() }
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        panel.contentView = NSHostingView(rootView: QuickPickerView(close: { [weak self] in self?.close() })
            .environment(AppModel.shared))
        panel.setContentSize(panel.contentView!.fittingSize)
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? .main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: frame.midX - panel.frame.width / 2,
                y: frame.minY + frame.height * 0.62 - panel.frame.height / 2
            ))
        }
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
        panel?.contentView = nil
    }

    private func makePanel() -> PickerPanel {
        let panel = PickerPanel(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: true
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.onResignKey = { [weak self] in self?.close() }
        return panel
    }
}

private final class PickerPanel: NSPanel {
    var onResignKey: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        onResignKey?()
    }

    override func cancelOperation(_ sender: Any?) {
        onResignKey?()
    }
}

struct QuickPickerView: View {
    @Environment(AppModel.self) private var model
    let close: () -> Void

    @State private var highlighted = "1x1"
    @State private var pendingIdeas: Int?
    @FocusState private var focused: Bool

    var body: some View {
        let label = model.spec.label(code: highlighted) ?? model.selectedLabel

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 28) {
                LabelGrid(spec: model.spec, selectedCode: highlighted, pendingIdeas: pendingIdeas) {
                    commit($0, as: .link)
                }
                LabelInfo(label: label)
            }

            BadgePreview(snippets: model.snippets(for: label))
                .frame(maxWidth: .infinity, minHeight: 31)

            Text(pendingIdeas == nil
                 ? "Type ideas 1–3, then words 1–3  ·  ↩ link  ·  ⌥↩ image  ·  ⇧↩ plain text"
                 : "Now words: 1 original · 2 some AI · 3 mostly AI")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .frame(width: 448)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear {
            highlighted = model.selectedCode
            focused = true
        }
        .onKeyPress(characters: .init(charactersIn: "123")) { press in
            guard let digit = Int(press.characters) else { return .ignored }
            if let ideas = pendingIdeas {
                pendingIdeas = nil
                highlighted = "\(ideas)x\(digit)"
            } else {
                pendingIdeas = digit
                highlighted = "\(digit)x\(model.spec.label(code: highlighted)?.words ?? 1)"
            }
            return .handled
        }
        .onKeyPress(keys: [.upArrow, .downArrow, .leftArrow, .rightArrow]) { press in
            move(press.key)
            return .handled
        }
        .onKeyPress(keys: [.return]) { press in
            let kind: ClipKind = press.modifiers.contains(.option) ? .image
                : press.modifiers.contains(.shift) ? .plainText : .link
            commit(label, as: kind)
            return .handled
        }
        .onKeyPress(.escape) {
            close()
            return .handled
        }
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    private func move(_ key: KeyEquivalent) {
        guard let current = model.spec.label(code: highlighted) else { return }
        var ideas = current.ideas, words = current.words
        switch key {
        case .upArrow: ideas -= 1
        case .downArrow: ideas += 1
        case .leftArrow: words -= 1
        case .rightArrow: words += 1
        default: break
        }
        pendingIdeas = nil
        highlighted = "\(min(max(ideas, 1), 3))x\(min(max(words, 1), 3))"
    }

    private func commit(_ label: AIALabel, as kind: ClipKind) {
        model.copy(label, as: kind, announce: true)
        close()
    }
}
