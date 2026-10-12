import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import LocalSendCore
import LocalSendUI

public struct IOSSendView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme

    @State private var isFileImporterPresented = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isManualSendPresented = false
    @State private var isTextSendPresented = false
    @State private var isTroubleshootPresented = false

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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingLarge) {

                    // 1. Active Transfers
                    if !engine.activeTransfers.isEmpty {
                        VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                            Text("Active Transfers")
                                .font(.title3.weight(.bold))

                            ForEach(engine.activeTransfers) { session in
                                TransferProgressCard(session: session, accentColor: accentColor) {
                                    engine.cancelTransfer(id: session.id)
                                }
                            }
                        }
                    }

                    // 2. Selected Files Section
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Selected Files")
                                    .font(.title3.weight(.bold))

                                if !engine.stagedFiles.isEmpty {
                                    Text("\(engine.stagedFiles.count) file\(engine.stagedFiles.count == 1 ? "" : "s") • \(LocalSendFormatters.formatFileSize(totalStagedSize))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if !engine.stagedFiles.isEmpty {
                                Button("Clear") {
                                    withAnimation(LocalSendMotion.snappy) {
                                        engine.clearStagedFiles()
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }

                        if engine.stagedFiles.isEmpty {
                            emptyFilePickerView
                        } else {
                            VStack(spacing: LocalSendTheme.spacingSmall) {
                                ForEach(engine.stagedFiles) { file in
                                    StagedFileItemView(file: file) {
                                        withAnimation(LocalSendMotion.snappy) {
                                            engine.removeStagedFile(id: file.id)
                                        }
                                    }
                                }

                                addMoreButtonsView
                            }
                        }
                    }

                    Divider()

                    // 3. Nearby Devices (AirDrop radar style)
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Nearby Devices")
                                    .font(.title3.weight(.bold))
                                Text(engine.stagedFiles.isEmpty ? "Select files, then choose recipient" : "Tap a device to send files")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: { isManualSendPresented = true }) {
                                Image(systemName: "network")
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundColor(accentColor)
                            .padding(.trailing, 8)

                            Button(action: {
                                withAnimation(LocalSendMotion.snappy) {
                                    engine.refreshDiscovery()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundColor(accentColor)
                        }

                        if engine.discoveredDevices.isEmpty {
                            VStack(spacing: LocalSendTheme.spacingMedium) {
                                RadarScanningView(isScanning: true, accentColor: accentColor)
                                    .frame(height: 160)

                                Text("Searching for nearby devices on Wi-Fi...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Button(action: { isTroubleshootPresented = true }) {
                                    Label("Troubleshoot Connection", systemImage: "wrench.and.screwdriver")
                                        .font(.caption.weight(.semibold))
                                }
                                .buttonStyle(.bordered)
                                .tint(accentColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, LocalSendTheme.spacingMedium)
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 140, maximum: 165), spacing: LocalSendTheme.spacingMedium)],
                                spacing: LocalSendTheme.spacingMedium
                            ) {
                                ForEach(engine.discoveredDevices) { device in
                                    DeviceCard(device: device, accentColor: accentColor) {
                                        if !engine.stagedFiles.isEmpty {
                                            engine.sendStagedFiles(to: device)
                                        } else {
                                            isFileImporterPresented = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Send")
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
            .sheet(isPresented: $isTroubleshootPresented) {
                TroubleshootView(engine: engine)
            }
            .onChange(of: selectedPhotoItems) { newItems in
                loadPhotos(items: newItems)
            }
        }
    }

    private var emptyFilePickerView: some View {
        VStack(spacing: LocalSendTheme.spacingMedium) {
            Image(systemName: "arrow.up.circle.badge.plus")
                .font(.system(size: 42))
                .foregroundColor(accentColor)

            Text("Choose files, photos or text to send")
                .font(.headline)

            HStack(spacing: LocalSendTheme.spacingMedium) {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    matching: .any(of: [.images, .videos]),
                    photoLibrary: .shared()
                ) {
                    Label("Photos", systemImage: "photo.on.rectangle")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(accentColor.opacity(0.14))
                        .foregroundColor(accentColor)
                        .clipShape(Capsule())
                }

                Button(action: { isFileImporterPresented = true }) {
                    Label("Files", systemImage: "folder")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(accentColor.opacity(0.14))
                        .foregroundColor(accentColor)
                        .clipShape(Capsule())
                }

                Button(action: { isTextSendPresented = true }) {
                    Label("Text", systemImage: "text.bubble")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(accentColor.opacity(0.14))
                        .foregroundColor(accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(LocalSendTheme.spacingLarge)
        .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
        )
    }

    private var addMoreButtonsView: some View {
        HStack(spacing: LocalSendTheme.spacingSmall) {
            PhotosPicker(
                selection: $selectedPhotoItems,
                matching: .any(of: [.images, .videos]),
                photoLibrary: .shared()
            ) {
                Label("Photos", systemImage: "photo")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            Button(action: { isFileImporterPresented = true }) {
                Label("Files", systemImage: "doc")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            Button(action: { isTextSendPresented = true }) {
                Label("Text", systemImage: "text.bubble")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(.top, 4)
    }

    private func loadPhotos(items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let data = data {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                    try? data.write(to: tempURL)
                    DispatchQueue.main.async {
                        self.engine.addStagedFiles(urls: [tempURL])
                    }
                }
            }
        }
    }
}
