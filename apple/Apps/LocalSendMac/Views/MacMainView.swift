import SwiftUI
import LocalSendCore
import LocalSendUI

public struct MacMainView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedItem: MacNavigationItem? = .send
    @State private var showingTroubleshoot = false
    @State private var showingAbout = false
    @State private var showingWebShare = false

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var accentColor: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    public var body: some View {
        NavigationSplitView {
            MacSidebarView(
                engine: engine,
                selection: $selectedItem,
                onOpenTroubleshoot: { showingTroubleshoot = true },
                onOpenAbout: { showingAbout = true },
                onOpenWebShare: { showingWebShare = true }
            )
        } detail: {
            ZStack {
                LocalSendTheme.windowBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
                    .ignoresSafeArea()

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
                    showingWebShare = true
                }) {
                    Label("Web Share", systemImage: "globe")
                }
                .help("Share files with web browsers on your Wi-Fi")

                Button(action: {
                    showingTroubleshoot = true
                }) {
                    Label("Troubleshoot", systemImage: "wrench.and.screwdriver")
                }
                .help("Connection & network troubleshooter")

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
        .sheet(isPresented: $showingTroubleshoot) {
            TroubleshootView(engine: engine)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView(engine: engine)
        }
        .sheet(isPresented: $showingWebShare) {
            WebShareView(engine: engine)
        }
    }
}
