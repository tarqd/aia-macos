import AIAKit
import SwiftUI

struct MenuBarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings
    /// Holding ⌥ switches clicks and drags from the link to the badge image.
    @State private var optionHeld = NSEvent.modifierFlags.contains(.option)
    @State private var flagsMonitor: Any?

    var body: some View {
        let label = model.selectedLabel
        let snippets = model.snippets(for: label)

        VStack(alignment: .leading, spacing: 14) {
            header(label: label, snippets: snippets)

            VStack(spacing: 8) {
                LabelGrid(spec: model.spec, selectedCode: model.selectedCode) { model.selectedCode = $0.code }

                Text(label.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    // Reserve two lines so the layout doesn't jump between labels.
                    .lineLimit(2, reservesSpace: true)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)

            badgeCard(label: label, snippets: snippets)
        }
        .padding(16)
        .frame(width: 448)
        .onAppear {
            optionHeld = NSEvent.modifierFlags.contains(.option) || Self.forceOption
            flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
                optionHeld = event.modifierFlags.contains(.option) || Self.forceOption
                return event
            }
        }
        .onDisappear {
            if let flagsMonitor { NSEvent.removeMonitor(flagsMonitor) }
            flagsMonitor = nil
        }
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
        let copied = model.justCopied.flatMap { $0.code == label.code ? $0.kind : nil }
        return VStack(spacing: 6) {
            Button { model.copy(label, as: currentKind) } label: {
                BadgePreview(snippets: snippets)
                    .frame(maxWidth: .infinity)
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
            .onDrag { LabelClip.itemProvider(snippets, as: currentKind) }
            .accessibilityLabel("Copy \(snippets.heading)")
            .accessibilityHint("Hold Option to copy the badge image instead")

            Group {
                if let copied {
                    Label(copied == .image ? "Copied image" : copied == .plainText ? "Copied plain text" : "Copied HTML + Markdown",
                          systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if optionHeld {
                    Label("Click or drag to use the image instead of the link", systemImage: "photo")
                        .foregroundStyle(.tint)
                } else {
                    Text("Click to copy  ·  Drag into a document")
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.caption)
            .contentTransition(.opacity)
            .animation(.default, value: copied)
            .animation(.easeOut(duration: 0.12), value: optionHeld)
        }
    }
}
