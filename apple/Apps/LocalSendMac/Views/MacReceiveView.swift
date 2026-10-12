import SwiftUI
import AppKit
import LocalSendCore
import LocalSendUI

public struct MacReceiveView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var accentColor: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LocalSendTheme.spacingLarge) {

                // Active Incoming Transfers
                let incomingTransfers = engine.activeTransfers.filter { $0.direction == .receiving }
                if !incomingTransfers.isEmpty {
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        HStack {
                            Text("Incoming Transfers")
                                .font(.title3.weight(.bold))

                            Spacer()

                            MorphingStatusPill(
                                status: .transferring(progress: incomingTransfers.first?.progress ?? 0),
                                accentColor: LocalSendTheme.success
                            )
                        }

                        ForEach(incomingTransfers) { session in
                            TransferProgressCard(session: session, accentColor: LocalSendTheme.success) {
                                engine.cancelTransfer(id: session.id)
                            }
                        }
                    }
                    Divider()
                }

                // Device Identity Beacon Card
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingMedium) {
                    HStack(spacing: LocalSendTheme.spacingLarge) {
                        RadarScanningView(isScanning: true, accentColor: accentColor)
                            .frame(width: 120, height: 120)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(engine.settings.alias)
                                    .font(.title2.weight(.bold))

                                Circle()
                                    .fill(LocalSendTheme.success)
                                    .frame(width: 8, height: 8)

                                Text("Online")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(LocalSendTheme.success)
                            }

                            Text("Visible to nearby devices on the local Wi-Fi and Ethernet network")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Label("Port \(engine.settings.port)", systemImage: "network")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Label(engine.settings.deviceType.displayName, systemImage: engine.settings.deviceType.systemImageName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(LocalSendTheme.spacingLarge)
                    .background(LocalSendTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                            .stroke(LocalSendTheme.borderSubtle, lineWidth: 1)
                    )
                }

                // Receive Settings Card
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingMedium) {
                    Text("Receive Configuration")
                        .font(.title3.weight(.bold))

                    VStack(spacing: LocalSendTheme.spacingMedium) {
                        // Destination Directory
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Destination Folder")
                                    .font(.headline)
                                Text(engine.settings.destinationDirectoryPath)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button("Show in Finder") {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: engine.settings.destinationDirectoryPath)
                            }
                            .buttonStyle(.bordered)

                            Button("Change...") {
                                chooseDestinationFolder()
                            }
                            .buttonStyle(.bordered)
                        }

                        Divider()

                        // Auto Accept Toggle
                        Toggle(isOn: $engine.settings.autoAccept) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Quick Save (Auto-Accept)")
                                    .font(.headline)
                                Text("Automatically save incoming files from anyone without asking for confirmation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        .tint(accentColor)
                        .onChange(of: engine.settings.autoAccept) { _ in
                            engine.settings.save()
                        }
                    }
                    .padding(LocalSendTheme.spacingLarge)
                    .background(LocalSendTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                            .stroke(LocalSendTheme.borderSubtle, lineWidth: 1)
                    )
                }

                // Network Interfaces Info
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    Text("Local Network Interfaces")
                        .font(.headline)

                    let interfaces = NetworkAddressHelper.getLocalIPv4Addresses()
                    if interfaces.isEmpty {
                        Text("No active Wi-Fi or Ethernet interfaces detected.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(interfaces, id: \.address) { iface in
                            HStack {
                                Image(systemName: "wifi")
                                    .foregroundColor(accentColor)
                                Text(iface.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(iface.address):\(engine.settings.port)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(LocalSendTheme.spacingLarge)
                .background(LocalSendTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                        .stroke(LocalSendTheme.borderSubtle, lineWidth: 1)
                )
            }
            .padding(LocalSendTheme.spacingLarge)
        }
    }

    private func chooseDestinationFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.prompt = "Select Destination"

        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            engine.settings.destinationDirectoryPath = selectedURL.path
            engine.settings.save()
        }
    }
}
