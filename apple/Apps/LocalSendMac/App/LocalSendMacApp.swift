import SwiftUI
import LocalSendCore
import LocalSendUI

@main
struct LocalSendMacApp: App {
    @StateObject private var engine = LocalSendEngine.shared

    var body: some Scene {
        WindowGroup {
            MacMainView(engine: engine)
                .frame(minWidth: 800, minHeight: 520)
                .preferredColorScheme(engine.settings.themeMode == .system ? nil : (engine.settings.themeMode == .dark ? .dark : .light))
                .onAppear {
                    engine.start()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Refresh Devices") {
                    engine.refreshDiscovery()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }

        Settings {
            MacSettingsView(engine: engine)
                .frame(width: 500, height: 420)
        }
    }
}
