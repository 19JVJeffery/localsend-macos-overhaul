import SwiftUI
import LocalSendCore
import LocalSendUI

public enum PadTabItem: String, CaseIterable, Identifiable {
    case send = "Send"
    case receive = "Receive"
    case history = "History"
    case settings = "Settings"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .send: return "arrow.up.circle.fill"
        case .receive: return "arrow.down.circle.fill"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct IOSPadSplitView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: PadTabItem? = .send

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var accentColor: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    public var body: some View {
        NavigationSplitView {
            List(PadTabItem.allCases, selection: $selectedTab) { item in
                NavigationLink(value: item) {
                    HStack {
                        Label(item.rawValue, systemImage: item.systemImage)
                            .font(.headline)
                            .padding(.vertical, 4)

                        Spacer()

                        badgeView(for: item)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("LocalSend")
        } detail: {
            switch selectedTab {
            case .send:
                IOSSendView(engine: engine)
            case .receive:
                IOSReceiveView(engine: engine)
            case .history:
                IOSHistoryView(engine: engine)
            case .settings:
                IOSSettingsView(engine: engine)
            case .none:
                IOSSendView(engine: engine)
            }
        }
        .tint(accentColor)
    }

    @ViewBuilder
    private func badgeView(for item: PadTabItem) -> some View {
        switch item {
        case .send:
            if !engine.stagedFiles.isEmpty {
                Text("\(engine.stagedFiles.count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.18))
                    .foregroundColor(accentColor)
                    .clipShape(Capsule())
            }
        case .receive:
            let incoming = engine.activeTransfers.filter { $0.direction == .receiving }.count
            if incoming > 0 {
                Text("\(incoming)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(LocalSendTheme.success.opacity(0.18))
                    .foregroundColor(LocalSendTheme.success)
                    .clipShape(Capsule())
            }
        case .history:
            if !engine.transferHistory.isEmpty {
                Text("\(engine.transferHistory.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        case .settings:
            EmptyView()
        }
    }
}
