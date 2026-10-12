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
    @State private var selectedTab: PadTabItem? = .send

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    public var body: some View {
        NavigationSplitView {
            List(PadTabItem.allCases, selection: $selectedTab) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.systemImage)
                        .font(.headline)
                        .padding(.vertical, 4)
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
    }
}
