import SwiftUI
import LocalSendCore
import LocalSendUI

@main
struct LocalSendIOSApp: App {
    @StateObject private var engine = LocalSendEngine.shared

    var body: some Scene {
        WindowGroup {
            AdaptiveRootView(engine: engine)
                .preferredColorScheme(engine.settings.themeMode == .system ? nil : (engine.settings.themeMode == .dark ? .dark : .light))
                .onAppear {
                    engine.start()
                }
        }
    }
}
