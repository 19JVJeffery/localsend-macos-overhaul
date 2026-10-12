import SwiftUI
import LocalSendCore
import LocalSendUI

public struct MacMainView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedItem: MacNavigationItem? = .send

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var accentColor: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    public var body: some View {
        NavigationSplitView {
            MacSidebarView(engine: engine, selection: $selectedItem)
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
        .tint(accentColor)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if !engine.activeTransfers.isEmpty {
                    MorphingStatusPill(
                        status: .transferring(progress: engine.activeTransfers.first?.progress ?? 0),
                        accentColor: accentColor
                    )
                }

                Button(action: {
                    withAnimation(LocalSendMotion.snappy) {
                        engine.refreshDiscovery()
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh nearby devices (⌘R)")
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
