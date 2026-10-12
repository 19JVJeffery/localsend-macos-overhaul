import SwiftUI
import UniformTypeIdentifiers
import LocalSendCore
import LocalSendUI

public struct MacSendView: View {
    @ObservedObject var engine: LocalSendEngine
    @State private var isTargetedForDrop = false
    @State private var isFileImporterPresented = false
    @State private var selectedDevice: Device?

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LocalSendTheme.spacingLarge) {

                // Active Transfers Section
                if !engine.activeTransfers.isEmpty {
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        Text("Active Transfers")
                            .font(.title3.weight(.bold))

                        ForEach(engine.activeTransfers) { session in
                            TransferProgressCard(session: session) {
                                engine.cancelTransfer(id: session.id)
                            }
                        }
                    }
                }

                // 1. Staged Files Section
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    HStack {
                        Text("Files to Send")
                            .font(.title3.weight(.bold))

                        Spacer()

                        if !engine.stagedFiles.isEmpty {
                            Button("Clear All") {
                                engine.clearStagedFiles()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            .font(.caption)
                        }

                        Button(action: { isFileImporterPresented = true }) {
                            Label("Add Files...", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                    }

                    // Drop Target & File List
                    if engine.stagedFiles.isEmpty {
                        dropTargetEmptyView
                    } else {
                        VStack(spacing: LocalSendTheme.spacingSmall) {
                            ForEach(engine.stagedFiles) { file in
                                StagedFileItemView(file: file) {
                                    engine.removeStagedFile(id: file.id)
                                }
                            }

                            // Quick add more drop banner
                            dropTargetMiniView
                        }
                    }
                }

                Divider()

                // 2. Nearby Devices (AirDrop style)
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nearby Devices")
                                .font(.title3.weight(.bold))
                            Text("Select a device to send the staged files")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: { engine.refreshDiscovery() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }

                    if engine.discoveredDevices.isEmpty {
                        EmptyStateView(
                            iconName: "antenna.radiowaves.left.and.right",
                            title: "Looking for Devices",
                            message: "Make sure LocalSend is open on other devices connected to the same Wi-Fi network."
                        )
                        .frame(height: 180)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 160), spacing: LocalSendTheme.spacingMedium)], spacing: LocalSendTheme.spacingMedium) {
                            ForEach(engine.discoveredDevices) { device in
                                DeviceCard(
                                    device: device,
                                    isSelected: selectedDevice?.id == device.id
                                ) {
                                    selectedDevice = device
                                    if !engine.stagedFiles.isEmpty {
                                        engine.sendStagedFiles(to: device)
                                    }
                                }
                                .help(engine.stagedFiles.isEmpty ? "Select files first to send to \(device.alias)" : "Click to send files to \(device.alias)")
                            }
                        }
                    }
                }
            }
            .padding(LocalSendTheme.spacingLarge)
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                engine.addStagedFiles(urls: urls)
            case .failure(let error):
                print("Failed to pick files: \(error)")
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
            handleDrop(providers: providers)
        }
    }

    private var dropTargetEmptyView: some View {
        Button(action: { isFileImporterPresented = true }) {
            VStack(spacing: LocalSendTheme.spacingSmall) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(isTargetedForDrop ? .accentColor : .secondary)

                Text("Drop files here or click to browse")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Supports any file, document, photo or folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(LocalSendTheme.spacingExtraLarge)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                    .strokeBorder(
                        isTargetedForDrop ? Color.accentColor : Color.secondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                            .fill(isTargetedForDrop ? Color.accentColor.opacity(0.08) : LocalSendTheme.cardBackground)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var dropTargetMiniView: some View {
        Button(action: { isFileImporterPresented = true }) {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(.secondary)
                Text("Drop more files or click to add")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(LocalSendTheme.spacingSmall)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusSmall, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
        }
        .buttonStyle(.plain)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var added = false
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        self.engine.addStagedFiles(urls: [url])
                    }
                    added = true
                } else if let url = item as? URL {
                    DispatchQueue.main.async {
                        self.engine.addStagedFiles(urls: [url])
                    }
                    added = true
                }
            }
        }
        return added
    }
}
