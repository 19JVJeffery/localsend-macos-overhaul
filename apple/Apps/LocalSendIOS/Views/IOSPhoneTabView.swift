import SwiftUI
import LocalSendCore
import LocalSendUI

public struct IOSPhoneTabView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var accentColor: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    public var body: some View {
        TabView {
            IOSSendView(engine: engine)
                .tabItem {
                    Label("Send", systemImage: "arrow.up.circle.fill")
                }
                .badge(engine.stagedFiles.count)

            IOSReceiveView(engine: engine)
                .tabItem {
                    Label("Receive", systemImage: "arrow.down.circle.fill")
                }
                .badge(engine.activeTransfers.filter { $0.direction == .receiving }.count)

            IOSHistoryView(engine: engine)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            IOSSettingsView(engine: engine)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(accentColor)
    }
}
