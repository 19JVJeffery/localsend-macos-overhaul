import SwiftUI
import LocalSendCore
import LocalSendUI

@main
struct LocalSendIOSApp: App {
    @StateObject private var engine = LocalSendEngine.shared

    var body: some Scene {
        WindowGroup {
            AdaptiveRootView(engine: engine)
                .onAppear {
                    engine.start()
                }
        }
    }
}
