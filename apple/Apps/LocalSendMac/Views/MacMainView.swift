import SwiftUI
import LocalSendCore
import LocalSendUI

public struct MacMainView: View {
    @ObservedObject var engine: LocalSendEngine
    @State private var selectedItem: MacNavigationItem? = .send

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    public var body: some View {
        NavigationSplitView {
            MacSidebarView(selection: $selectedItem)
        } detail: {
            switch selectedItem {
            case .send:
                MacSendView(engine: engine)
            case .receive:
                MacReceiveView(engine: engine)
            case .history:
                MacHistoryView(engine: engine)
            case .settings:
                MacSettingsView(engine: engine)
            case .none:
                MacSendView(engine: engine)
            }
        }
        .navigationTitle(selectedItem?.rawValue ?? "LocalSend")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { engine.refreshDiscovery() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh nearby devices")
            }
        }
        .sheet(item: $engine.incomingRequest) { request in
            MacReceiveModal(
                session: request,
                onAccept: { engine.acceptIncomingRequest() },
                onDecline: { engine.declineIncomingRequest() }
            )
        }
    }
}
