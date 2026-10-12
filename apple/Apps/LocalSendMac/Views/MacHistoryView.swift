import SwiftUI
import AppKit
import LocalSendCore
import LocalSendUI

public struct MacHistoryView: View {
    @ObservedObject var engine: LocalSendEngine
    @State private var searchText = ""

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var filteredHistory: [TransferHistoryItem] {
        if searchText.isEmpty {
            return engine.transferHistory
        }
        return engine.transferHistory.filter { item in
            item.remoteDeviceAlias.localizedCaseInsensitiveContains(searchText) ||
            item.fileNames.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text("Transfer History")
                    .font(.title2.weight(.bold))

                Spacer()

                if !engine.transferHistory.isEmpty {
                    Button("Clear History") {
                        engine.clearHistory()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                }
            }
            .padding(.horizontal, LocalSendTheme.spacingLarge)
            .padding(.top, LocalSendTheme.spacingLarge)
            .padding(.bottom, LocalSendTheme.spacingSmall)

            if engine.transferHistory.isEmpty {
                EmptyStateView(
                    iconName: "clock.arrow.circlepath",
                    title: "No Transfer History",
                    message: "Past sent and received file transfers will appear here."
                )
            } else {
                List {
                    ForEach(filteredHistory) { item in
                        historyRow(item: item)
                    }
                }
                .searchable(text: $searchText, prompt: "Search files or devices")
            }
        }
    }

    private func historyRow(item: TransferHistoryItem) -> some View {
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

            if !item.destinationPaths.isEmpty {
                Button(action: {
                    if let first = item.destinationPaths.first {
                        NSWorkspace.shared.selectFile(first, inFileViewerRootedAtPath: "")
                    }
                }) {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Show in Finder")
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            if !item.destinationPaths.isEmpty {
                Button("Show in Finder") {
                    if let first = item.destinationPaths.first {
                        NSWorkspace.shared.selectFile(first, inFileViewerRootedAtPath: "")
                    }
                }
            }
        }
    }
}
