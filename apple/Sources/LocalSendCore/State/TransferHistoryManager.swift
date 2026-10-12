import Foundation

public final class TransferHistoryManager: @unchecked Sendable {
    private let userDefaultsKey = "localsend_transfer_history"
    private let queue = DispatchQueue(label: "org.localsend.history")

    public static let shared = TransferHistoryManager()

    private init() {}

    public func loadHistory() -> [TransferHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let items = try? JSONDecoder().decode([TransferHistoryItem].self, from: data) else {
            return []
        }
        return items
    }

    public func addHistoryItem(_ item: TransferHistoryItem) {
        queue.sync {
            var items = loadHistory()
            items.insert(item, at: 0)
            if items.count > 100 {
                items = Array(items.prefix(100))
            }
            if let data = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(data, forKey: userDefaultsKey)
            }
        }
    }

    public func clearHistory() {
        queue.sync {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }

    public func deleteItem(id: String) {
        queue.sync {
            var items = loadHistory()
            items.removeAll { $0.id == id }
            if let data = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(data, forKey: userDefaultsKey)
            }
        }
    }
}
