import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import LocalSendCore
import LocalSendUI

public struct IOSSendView: View {
    @ObservedObject var engine: LocalSendEngine
    @State private var isFileImporterPresented = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isTargetedForDrop = false

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingLarge) {

                    // Active Transfers
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
                            Text("Selected Files")
                                .font(.title3.weight(.bold))

                            Spacer()

                            if !engine.stagedFiles.isEmpty {
                                Button("Clear") {
                                    engine.clearStagedFiles()
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
                                        engine.removeStagedFile(id: file.id)
                                    }
                                }

                                addMoreButtonsView
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
                                Text("Tap a device to send")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: { engine.refreshDiscovery() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.body.weight(.semibold))
                            }
                        }

                        if engine.discoveredDevices.isEmpty {
                            EmptyStateView(
                                iconName: "antenna.radiowaves.left.and.right",
                                title: "Searching for Devices",
                                message: "Open LocalSend on other devices connected to this Wi-Fi network."
                            )
                            .frame(height: 160)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 160), spacing: LocalSendTheme.spacingMedium)], spacing: LocalSendTheme.spacingMedium) {
                                ForEach(engine.discoveredDevices) { device in
                                    DeviceCard(device: device) {
                                        if !engine.stagedFiles.isEmpty {
                                            engine.sendStagedFiles(to: device)
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
            .onChange(of: selectedPhotoItems) { newItems in
                loadPhotos(items: newItems)
            }
        }
    }

    private var emptyFilePickerView: some View {
        VStack(spacing: LocalSendTheme.spacingMedium) {
            Image(systemName: "arrow.up.circle.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("Choose files or photos to send")
                .font(.headline)

            HStack(spacing: LocalSendTheme.spacingMedium) {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    matching: .any(of: [.images, .videos]),
                    photoLibrary: .shared()
                ) {
                    Label("Photos", systemImage: "photo.on.rectangle")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                Button(action: { isFileImporterPresented = true }) {
                    Label("Files", systemImage: "folder")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(LocalSendTheme.spacingLarge)
        .background(LocalSendTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
    }

    private var addMoreButtonsView: some View {
        HStack(spacing: LocalSendTheme.spacingMedium) {
            PhotosPicker(
                selection: $selectedPhotoItems,
                matching: .any(of: [.images, .videos]),
                photoLibrary: .shared()
            ) {
                Label("Add Photos", systemImage: "photo")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            Button(action: { isFileImporterPresented = true }) {
                Label("Add Files", systemImage: "doc")
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
