import KeyboardShortcuts
import SwiftUI

@main
struct AIALabelsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel.shared

    var body: some Scene {
        MenuBarExtra("AIA Labels", systemImage: "square.grid.3x3.square") {
            MenuBarView()
                .environment(model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        KeyboardShortcuts.onKeyUp(for: .openPicker) {
            QuickPicker.shared.toggle()
        }
        #if DEBUG
        DebugPreview.showIfRequested()
        #endif
    }
}

#if DEBUG
/// `-AIAPreview picker|menu` opens a window on launch, for screenshots without clicking the menu bar.
@MainActor
enum DebugPreview {
    private static var window: NSWindow?

    static func showIfRequested() {
        switch UserDefaults.standard.string(forKey: "AIAPreview") {
        case "picker":
            QuickPicker.shared.show()
        case "menu":
            let window = NSWindow(contentViewController: NSHostingController(
                rootView: MenuBarView().environment(AppModel.shared)))
            window.title = "AIA Labels (preview)"
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            self.window = window
        default:
            break
        }
    }
}
#endif
