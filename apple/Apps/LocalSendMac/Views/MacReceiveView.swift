import SwiftUI
import AppKit
import LocalSendCore
import LocalSendUI

public struct MacReceiveView: View {
    @ObservedObject var engine: LocalSendEngine

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LocalSendTheme.spacingLarge) {

                // Active Incoming Transfers
                let incomingTransfers = engine.activeTransfers.filter { $0.direction == .receiving }
                if !incomingTransfers.isEmpty {
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        Text("Incoming Transfers")
                            .font(.title3.weight(.bold))

                        ForEach(incomingTransfers) { session in
                            TransferProgressCard(session: session) {
                                engine.cancelTransfer(id: session.id)
                            }
                        }
                    }
                    Divider()
                }

                // Device Identity Banner
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingMedium) {
                    HStack(spacing: LocalSendTheme.spacingMedium) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 26))
                                .foregroundColor(.green)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(engine.settings.alias)
                                    .font(.title2.weight(.bold))

                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }

                            Text("Visible to nearby devices on the local network")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(LocalSendTheme.spacingMedium)
                    .background(LocalSendTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
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
                                Text("Automatically accept and save incoming file transfers from everyone")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        .onChange(of: engine.settings.autoAccept) { _ in
                            engine.settings.save()
                        }
                    }
                    .padding(LocalSendTheme.spacingMedium)
                    .background(LocalSendTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
                }

                // Network Interfaces Info
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    Text("Network Information")
                        .font(.headline)

                    let interfaces = NetworkAddressHelper.getLocalIPv4Addresses()
                    if interfaces.isEmpty {
                        Text("No active Wi-Fi or Ethernet interfaces detected.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(interfaces, id: \.address) { iface in
                            HStack {
                                Image(systemName: "network")
                                    .foregroundColor(.secondary)
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
                .padding(LocalSendTheme.spacingMedium)
                .background(LocalSendTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
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
