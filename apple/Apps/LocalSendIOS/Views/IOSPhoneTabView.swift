import SwiftUI
import LocalSendCore

public struct IOSPhoneTabView: View {
    @ObservedObject var engine: LocalSendEngine

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    public var body: some View {
        TabView {
            IOSSendView(engine: engine)
                .tabItem {
                    Label("Send", systemImage: "arrow.up.circle.fill")
                }

            IOSReceiveView(engine: engine)
                .tabItem {
                    Label("Receive", systemImage: "arrow.down.circle.fill")
                }

            IOSHistoryView(engine: engine)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            IOSSettingsView(engine: engine)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
