import SwiftUI
import LocalSendCore
import LocalSendUI

public enum MacNavigationItem: String, CaseIterable, Identifiable {
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

public struct MacSidebarView: View {
    @ObservedObject var engine: LocalSendEngine
    @Binding public var selection: MacNavigationItem?

    public init(engine: LocalSendEngine, selection: Binding<MacNavigationItem?>) {
        self.engine = engine
        self._selection = selection
    }

    public var body: some View {
        List(MacNavigationItem.allCases, selection: $selection) { item in
            NavigationLink(value: item) {
                HStack {
                    Label(item.rawValue, systemImage: item.systemImage)
                        .font(.headline)

                    Spacer()

                    badgeView(for: item)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 190, idealWidth: 210)
    }

    @ViewBuilder
    private func badgeView(for item: MacNavigationItem) -> some View {
        switch item {
        case .send:
            if !engine.stagedFiles.isEmpty {
                Text("\(engine.stagedFiles.count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.18))
                    .foregroundColor(.accentColor)
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
