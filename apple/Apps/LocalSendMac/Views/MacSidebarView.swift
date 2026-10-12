import SwiftUI

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
    @Binding public var selection: MacNavigationItem?

    public init(selection: Binding<MacNavigationItem?>) {
        self._selection = selection
    }

    public var body: some View {
        List(MacNavigationItem.allCases, selection: $selection) { item in
            NavigationLink(value: item) {
                Label(item.rawValue, systemImage: item.systemImage)
                    .font(.headline)
                    .padding(.vertical, 4)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 200)
    }
}
