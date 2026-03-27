import SwiftUI

@main
struct RimeConfiguratorApp: App {
    @StateObject private var configManager = ConfigManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configManager)
                .frame(minWidth: 820, minHeight: 580)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 960, height: 640)
        .commands {
            CommandGroup(replacing: .newItem) { }   // hide "New Window"
            CommandGroup(after: .appInfo) {
                Button(configManager.strings.saveAndDeployMenu) {
                    NotificationCenter.default.post(
                        name: .init("deployRime"), object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}
