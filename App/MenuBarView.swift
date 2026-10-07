import AIAKit
import SwiftUI

struct MenuBarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        let label = model.selectedLabel
        let snippets = model.snippets(for: label)

        VStack(alignment: .leading, spacing: 14) {
            header(label: label, snippets: snippets)

            LabelGrid(spec: model.spec, selectedCode: model.selectedCode) { model.selectedCode = $0.code }
                .frame(maxWidth: .infinity)

            badgeCard(label: label, snippets: snippets)

            Text(label.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button { model.copy(label, as: .link) } label: {
                    Label("Copy Label", systemImage: "doc.on.doc")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(Color(hex: label.dark))
                .help("HTML badge for rich editors, Markdown for plain text")

                Button { model.copy(label, as: .image) } label: {
                    Label("Copy Image", systemImage: "photo").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .onDrag { LabelClip.itemProvider(snippets, as: .image) }
                .help("Copy the badge as a PNG, or drag it out")
            }
            .controlSize(.large)
        }
        .padding(16)
        .frame(width: 448)
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
        let copied = model.justCopied == label.code
        return Button { model.copy(label, as: .link) } label: {
            VStack(spacing: 10) {
                BadgePreview(snippets: snippets)
                Group {
                    if copied {
                        Label("Copied HTML + Markdown", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text("Click to copy  ·  Drag into a document")
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.caption)
                .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: 12))
            .contentShape(.rect)
            .animation(.default, value: copied)
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .onDrag { LabelClip.itemProvider(snippets, as: .link) }
        .accessibilityLabel("Copy \(snippets.heading)")
    }
}
