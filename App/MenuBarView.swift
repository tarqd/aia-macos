import AIAKit
import SwiftUI

struct MenuBarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var model = model
        let label = model.selectedLabel
        let snippets = model.snippets(for: label)

        VStack(alignment: .leading, spacing: 14) {
            LabelGrid(spec: model.spec, selectedCode: model.selectedCode) { model.selectedCode = $0.code }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Button {
                    model.copy(label, as: .link)
                } label: {
                    BadgePreview(snippets: snippets)
                        .overlay {
                            if model.justCopied == label.code {
                                Label("Copied", systemImage: "checkmark")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .glassEffect()
                                    .transition(.opacity)
                            }
                        }
                        .animation(.default, value: model.justCopied)
                }
                .buttonStyle(.plain)
                .onDrag { LabelClip.itemProvider(snippets, as: .link) }
                .help("Click to copy as HTML + Markdown, or drag into a document")
                .accessibilityLabel("Copy \(snippets.heading)")

                Text(label.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button("Copy Image", systemImage: "photo") { model.copy(label, as: .image) }
                    .onDrag { LabelClip.itemProvider(snippets, as: .image) }
                    .help("Copy the badge as a PNG, or drag it out")
                Menu("More") {
                    Button("Copy Plain Text") { model.copy(label, as: .plainText) }
                    Button("Copy Page Head Tags") { model.copyPageHead(label) }
                    Divider()
                    Link("About \(label.code) on timothyfcook.com", destination: URL(string: snippets.pageURL)!)
                }
                .fixedSize()

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
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Label size and style")
            }
            .controlSize(.small)

            Divider()

            HStack {
                Button("Settings…") {
                    NSApp.activate()
                    openSettings()
                }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(16)
        .frame(width: 420)
    }
}
