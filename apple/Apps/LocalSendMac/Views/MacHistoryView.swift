import SwiftUI
import AppKit
import LocalSendCore
import LocalSendUI

public struct MacHistoryView: View {
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
        VStack(spacing: 0) {
            // Header bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Transfer History")
                        .font(.title2.weight(.bold))
                    Text("Recent incoming and outgoing file transfers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: openDownloadFolder) {
                    Label("Open Folder", systemImage: "folder")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .help("Open default download folder in Finder")

                if !engine.transferHistory.isEmpty {
                    Button(action: { showingClearAlert = true }) {
                        Label("Clear", systemImage: "trash")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.secondary)
                    .help("Clear all transfer history")
                }
            }
            .padding(.horizontal, LocalSendTheme.spacingLarge)
            .padding(.top, LocalSendTheme.spacingLarge)
            .padding(.bottom, LocalSendTheme.spacingMedium)

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
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                                    .fill(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
                                    .padding(.vertical, 3)
                            )
                    }
                }
                .listStyle(.inset)
                .searchable(text: $searchText, prompt: "Search files or devices")
            }
        }
        .background(LocalSendTheme.windowBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
        .alert("Clear Transfer History?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                withAnimation(LocalSendMotion.snappy) {
                    engine.clearHistory()
                }
            }
        } message: {
            Text("This will remove all transfer records from history. Downloaded files on disk will not be deleted.")
        }
    }

    private func historyRow(item: TransferHistoryItem) -> some View {
        HStack(spacing: LocalSendTheme.spacingMedium) {
            ZStack {
                Circle()
                    .fill((item.direction == .sending ? accentColor : LocalSendTheme.success).opacity(0.15))
                    .frame(width: 38, height: 38)

                Image(systemName: item.direction == .sending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(item.direction == .sending ? accentColor : LocalSendTheme.success)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
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
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("Show in Finder")
            }
        }
        .padding(.vertical, 6)
        .contextMenu {
            if !item.destinationPaths.isEmpty {
                Button("Show in Finder") {
                    if let first = item.destinationPaths.first {
                        NSWorkspace.shared.selectFile(first, inFileViewerRootedAtPath: "")
                    }
                }
            }

            Button(role: .destructive) {
                withAnimation(LocalSendMotion.snappy) {
                    engine.deleteHistoryItem(id: item.id)
                }
            } label: {
                Label("Delete from History", systemImage: "trash")
            }
        }
    }

    private func openDownloadFolder() {
        let path = engine.settings.destinationDirectoryPath
        if !path.isEmpty {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }
}
