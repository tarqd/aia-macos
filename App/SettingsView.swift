import AIAKit
import KeyboardShortcuts
import ServiceManagement
import SwiftUI

extension KeyboardShortcuts.Name {
    static let openPicker = Self("openPicker", initial: .init(.a, modifiers: [.control, .option]))
}

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        @Bindable var model = model

        Form {
            Section("Label") {
                Picker("Size", selection: $model.options.size) {
                    ForEach(BadgeSize.allCases, id: \.self) { Text($0.displayName) }
                }
                Picker("Style", selection: $model.options.style) {
                    ForEach(BadgeStyle.allCases, id: \.self) { Text($0.displayName) }
                }
                Picker("Linked image", selection: $model.options.format) {
                    ForEach(ImageFormat.allCases, id: \.self) { Text($0.displayName) }
                }
                LabeledContent("Preview") {
                    BadgePreview(snippets: model.snippets(for: model.selectedLabel))
                }
            }

            Section {
                KeyboardShortcuts.Recorder("Open label picker", name: .openPicker)
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            } footer: {
                Text("Copying puts HTML and Markdown on the clipboard together. Rich editors paste the badge; plain-text editors paste Markdown.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Link("AI Attribution labels by Timothy F. Cook", destination: URL(string: "https://timothyfcook.com/aia")!)
                Link("Label artwork licensed \(model.spec.license.name)", destination: model.spec.license.url)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}
