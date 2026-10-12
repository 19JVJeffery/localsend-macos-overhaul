import SwiftUI
import LocalSendCore
import LocalSendUI

public struct IOSHistoryView: View {
    @ObservedObject var engine: LocalSendEngine
    @State private var shareURL: URL?

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    public var body: some View {
        NavigationStack {
            Group {
                if engine.transferHistory.isEmpty {
                    EmptyStateView(
                        iconName: "clock.arrow.circlepath",
                        title: "No History",
                        message: "Transferred files will appear here."
                    )
                } else {
                    List {
                        ForEach(engine.transferHistory) { item in
                            HStack(spacing: LocalSendTheme.spacingMedium) {
                                Image(systemName: item.direction == .sending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(item.direction == .sending ? .accentColor : .green)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.direction == .sending ? "Sent to \(item.remoteDeviceAlias)" : "Received from \(item.remoteDeviceAlias)")
                                        .font(.headline)

                                    Text(item.fileNames.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)

                                    Text("\(LocalSendFormatters.formatFileSize(item.totalSize)) • \(LocalSendFormatters.formatDate(item.date))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                StatusBadge(status: item.status)

                                if let first = item.destinationPaths.first {
                                    ShareLink(item: URL(fileURLWithPath: first)) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !engine.transferHistory.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            engine.clearHistory()
                        }
                    }
                }
            }
        }
    }
}
