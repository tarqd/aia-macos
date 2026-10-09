import AIAKit
import SwiftUI

struct MenuBarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings
    /// Holding ⌥ switches clicks and drags from the link to the badge image.
    @State private var optionHeld = NSEvent.modifierFlags.contains(.option)
    @State private var flagsMonitor: Any?
    /// Scrolling over the badge card steps through sizes.
    @State private var scrollMonitor: Any?
    @State private var scrollAccumulator: CGFloat = 0
    @State private var cardHovered = false
    /// The grid cell under the pointer, previewed until the pointer leaves the grid.
    @State private var hoveredCode: String?

    var body: some View {
        let label = model.selectedLabel
        let snippets = model.snippets(for: label)
        let preview = hoveredCode.flatMap(model.spec.label(code:)) ?? label

        VStack(alignment: .leading, spacing: 14) {
            header(label: label, snippets: snippets)

            HStack(alignment: .center, spacing: 20) {
                LabelGrid(spec: model.spec, selectedCode: model.selectedCode,
                          onHover: { hoveredCode = $0?.code }) { model.selectedCode = $0.code }

                LabelInfo(label: preview)
            }

            badgeCard(label: preview, snippets: model.snippets(for: preview))
        }
        .padding(16)
        .frame(width: 448)
        .onAppear {
            optionHeld = NSEvent.modifierFlags.contains(.option) || Self.forceOption
            flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
                optionHeld = event.modifierFlags.contains(.option) || Self.forceOption
                return event
            }
            scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                guard cardHovered else { return event }
                scrollSize(by: event)
                return nil
            }
        }
        .onDisappear {
            for monitor in [flagsMonitor, scrollMonitor].compactMap(\.self) { NSEvent.removeMonitor(monitor) }
            flagsMonitor = nil
            scrollMonitor = nil
        }
    }

    /// One wheel notch, or a short trackpad swipe, moves one size. Momentum is ignored so a
    /// flick doesn't fly past the size you wanted.
    private func scrollSize(by event: NSEvent) {
        guard event.momentumPhase.isEmpty else { return }
        if event.phase == .began { scrollAccumulator = 0 }
        let delta = abs(event.scrollingDeltaY) >= abs(event.scrollingDeltaX) ? event.scrollingDeltaY : -event.scrollingDeltaX
        scrollAccumulator += event.hasPreciseScrollingDeltas ? delta : delta * 12
        guard abs(scrollAccumulator) >= 12 else { return }
        // Scrolling down (or swiping left) moves toward smaller sizes.
        model.options.size = model.options.size.stepped(by: scrollAccumulator < 0 ? -1 : 1)
        scrollAccumulator = 0
    }

    #if DEBUG
    /// `-AIAPreviewOption YES` renders the ⌥ state for screenshots.
    private static let forceOption = UserDefaults.standard.bool(forKey: "AIAPreviewOption")
    #else
    private static let forceOption = false
    #endif

    /// Reads the live modifier state so a click or drag that starts with ⌥ held always gets the image.
    private var currentKind: ClipKind {
        NSEvent.modifierFlags.contains(.option) ? .image : .link
    }

    private func header(label: AIALabel, snippets: Snippets) -> some View {
        @Bindable var model = model
        return HStack {
            Text("AI Attribution")
                .font(.headline)
            Spacer()
            Menu {
                Picker("Size", selection: $model.options.size) {
                    ForEach(BadgeSize.allCases, id: \.self) { Text($0.displayName) }
                }
                Picker("Style", selection: $model.options.style) {
                    ForEach(BadgeStyle.allCases, id: \.self) { Text($0.displayName) }
                }
                Picker("Linked Image", selection: $model.options.format) {
                    ForEach(ImageFormat.allCases, id: \.self) { Text($0.displayName) }
                }
                Divider()
                Button("Copy Plain Text") { model.copy(label, as: .plainText) }
                Button("Copy Page Head Tags") { model.copyPageHead(label) }
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .help("Label size, style, and other formats")
            Menu {
                Button("Settings…") {
                    NSApp.activate()
                    openSettings()
                }
                Link("About \(label.code) on timothyfcook.com", destination: URL(string: snippets.pageURL)!)
                Divider()
                Button("Quit AIA Labels") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .menuStyle(.button)
        .buttonStyle(.borderless)
        .menuIndicator(.hidden)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The finished badge: click to copy, drag to insert.
    private func badgeCard(label: AIALabel, snippets: Snippets) -> some View {
        @Bindable var model = model
        let copied = model.justCopied.flatMap { $0.code == label.code ? $0.kind : nil }
        return VStack(spacing: 6) {
            // Hint above the card: shown on hover, and for copy and ⌥ feedback.
            Group {
                if let copied {
                    Label(copied == .image ? "Copied image" : copied == .plainText ? "Copied plain text" : "Copied HTML + Markdown",
                          systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if optionHeld {
                    Label("Click or drag as an image", systemImage: "photo")
                        .foregroundStyle(.tint)
                } else {
                    Text("Click to copy or drag and drop")
                        .foregroundStyle(.tertiary)
                        .opacity(cardHovered ? 1 : 0)
                }
            }
            .font(.caption)
            .frame(height: 16)
            .contentTransition(.opacity)
            .animation(.default, value: copied)
            .animation(.easeOut(duration: 0.12), value: optionHeld)
            .animation(.easeOut(duration: 0.15), value: cardHovered)

            Button { model.copy(label, as: currentKind) } label: {
                BadgePreview(snippets: snippets)
                    // Keep the card the same height across sizes.
                    .frame(maxWidth: .infinity, minHeight: 31)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
                    .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.accentColor.opacity(optionHeld ? 0.8 : 0), style: .init(lineWidth: 1.5, dash: [5, 3]))
                    }
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .pointerStyle(.link)
            .onDrag { LabelClip.itemProvider(snippets, as: currentKind) }
            .onHover { cardHovered = $0 }
            .animation(.snappy(duration: 0.2), value: model.options.size)
            .accessibilityLabel("Copy \(snippets.heading)")
            .accessibilityHint("Click to copy or drag and drop. Hold Option to use the badge image instead.")

            SizeStrip(size: $model.options.size, emphasized: cardHovered)
                .frame(height: 16)
        }
    }
}

/// Name and description of the hovered or selected label, beside the grid.
struct LabelInfo: View {
    let label: AIALabel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(label.name)
                    .font(.title3.weight(.semibold))
                Text(label.code)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(label.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                // Reserve space so the layout doesn't jump between labels.
                .lineLimit(5, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
