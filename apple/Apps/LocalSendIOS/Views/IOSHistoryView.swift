import SwiftUI
import LocalSendCore
import LocalSendUI

public struct IOSHistoryView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var showingClearAlert = false

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var accentColor: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
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
                        ForEach(filteredHistory) { item in
                            HStack(spacing: LocalSendTheme.spacingMedium) {
                                Image(systemName: item.direction == .sending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(item.direction == .sending ? accentColor : LocalSendTheme.success)
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
                                            .foregroundColor(accentColor)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .searchable(text: $searchText, prompt: "Search files or devices")
                }
            }
            .navigationTitle("History")
            .tint(accentColor)
            .toolbar {
                if !engine.transferHistory.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showingClearAlert = true
                        } label: {
                            Text("Clear")
                        }
                    }
                }
            }
            .alert("Clear Transfer History?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    withAnimation(LocalSendMotion.snappy) {
                        engine.clearHistory()
                    }
                }
            } message: {
                Text("This will remove all transfer records from history.")
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredHistory[index]
            withAnimation(LocalSendMotion.snappy) {
                engine.deleteHistoryItem(id: item.id)
            }
        }
    }
}
