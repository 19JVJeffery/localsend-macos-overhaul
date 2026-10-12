import SwiftUI
import UniformTypeIdentifiers
import AppKit
import LocalSendCore
import LocalSendUI

public struct MacSendView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme

    @State private var isTargetedForDrop = false
    @State private var isFileImporterPresented = false
    @State private var isManualSendPresented = false
    @State private var isTextSendPresented = false
    @State private var selectedDevice: Device?

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var accentColor: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    private var totalStagedSize: Int64 {
        engine.stagedFiles.reduce(0) { $0 + $1.size }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LocalSendTheme.spacingLarge) {

                // 1. Active Transfers Section
                if !engine.activeTransfers.isEmpty {
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        HStack {
                            Text("Active Transfers")
                                .font(.title3.weight(.bold))

                            Spacer()

                            MorphingStatusPill(
                                status: .transferring(progress: engine.activeTransfers.first?.progress ?? 0),
                                accentColor: accentColor
                            )
                        }

                        ForEach(engine.activeTransfers) { session in
                            TransferProgressCard(session: session, accentColor: accentColor) {
                                engine.cancelTransfer(id: session.id)
                            }
                        }
                    }
                    Divider()
                }

                // 2. Files to Send Section
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Files to Send")
                                .font(.title3.weight(.bold))

                            if !engine.stagedFiles.isEmpty {
                                Text("\(engine.stagedFiles.count) file\(engine.stagedFiles.count == 1 ? "" : "s") • \(LocalSendFormatters.formatFileSize(totalStagedSize))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Action Buttons: Files, Folder, Text, Clear
                        if !engine.stagedFiles.isEmpty {
                            Button("Clear All") {
                                withAnimation(LocalSendMotion.snappy) {
                                    engine.clearStagedFiles()
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .padding(.trailing, 4)
                        }

                        Menu {
                            Button(action: { isFileImporterPresented = true }) {
                                Label("Add Files...", systemImage: "doc.badge.plus")
                            }
                            Button(action: { chooseFolder() }) {
                                Label("Add Folder...", systemImage: "folder.badge.plus")
                            }
                            Button(action: { isTextSendPresented = true }) {
                                Label("Send Text / Clipboard...", systemImage: "text.bubble")
                            }
                        } label: {
                            Label("Add...", systemImage: "plus")
                        }
                        .menuStyle(.borderedButton)
                    }

                    // Drop Target & File List
                    if engine.stagedFiles.isEmpty {
                        dropTargetEmptyView
                    } else {
                        VStack(spacing: LocalSendTheme.spacingSmall) {
                            ForEach(engine.stagedFiles) { file in
                                StagedFileItemView(file: file) {
                                    withAnimation(LocalSendMotion.snappy) {
                                        engine.removeStagedFile(id: file.id)
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                                    removal: .opacity.combined(with: .move(edge: .trailing))
                                ))
                            }

                            dropTargetMiniView
                        }
                        .animation(LocalSendMotion.standard, value: engine.stagedFiles)
                    }
                }

                Divider()

                // 3. Nearby Devices (AirDrop radar style)
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingMedium) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nearby Devices")
                                .font(.title3.weight(.bold))
                            Text(engine.stagedFiles.isEmpty ? "Select files above, then choose a recipient" : "Click a device to start transfer")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: { isManualSendPresented = true }) {
                            Label("Send to IP...", systemImage: "network")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button(action: { engine.refreshDiscovery() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.body.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(accentColor)
                        .help("Refresh nearby devices")
                    }

                    if engine.discoveredDevices.isEmpty {
                        VStack(spacing: LocalSendTheme.spacingMedium) {
                            RadarScanningView(isScanning: true, accentColor: accentColor)
                                .frame(height: 180)

                            Text("Scanning local network for LocalSend devices...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LocalSendTheme.spacingLarge)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 140, maximum: 170), spacing: LocalSendTheme.spacingMedium)],
                            spacing: LocalSendTheme.spacingMedium
                        ) {
                            ForEach(engine.discoveredDevices) { device in
                                DeviceCard(
                                    device: device,
                                    isSelected: selectedDevice?.id == device.id,
                                    accentColor: accentColor
                                ) {
                                    selectedDevice = device
                                    if !engine.stagedFiles.isEmpty {
                                        engine.sendStagedFiles(to: device)
                                    }
                                }
                                .help(engine.stagedFiles.isEmpty ? "Select files first to send to \(device.alias)" : "Click to send files to \(device.alias)")
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(LocalSendMotion.standard, value: engine.discoveredDevices)
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
            if case .success(let urls) = result {
                engine.addStagedFiles(urls: urls)
            }
        }
        .sheet(isPresented: $isManualSendPresented) {
            ManualSendDialog(isPresented: $isManualSendPresented) { ip, port in
                engine.sendStagedFiles(toIP: ip, port: port)
            }
        }
        .sheet(isPresented: $isTextSendPresented) {
            SendTextMessageDialog(isPresented: $isTextSendPresented) { text in
                engine.stageTextMessage(text)
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
                    .font(.system(size: 38, weight: .light))
                    .foregroundColor(isTargetedForDrop ? accentColor : .secondary)

                Text("Drop files here or click to browse")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Supports documents, folders, images, videos or archives")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(LocalSendTheme.spacingXL)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                    .strokeBorder(
                        isTargetedForDrop ? accentColor : Color.secondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                            .fill(isTargetedForDrop ? accentColor.opacity(0.08) : LocalSendTheme.cardBackground)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isTargetedForDrop ? 1.02 : 1.0)
        .animation(LocalSendMotion.snappy, value: isTargetedForDrop)
    }

    private var dropTargetMiniView: some View {
        Button(action: { isFileImporterPresented = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(accentColor)
                Text("Drop more files or click to add")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(LocalSendTheme.spacingSmall)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
        }
        .buttonStyle(.plain)
    }

    private func chooseFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = true
        openPanel.prompt = "Select Folder"
        if openPanel.runModal() == .OK {
            engine.addStagedFiles(urls: openPanel.urls)
        }
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
