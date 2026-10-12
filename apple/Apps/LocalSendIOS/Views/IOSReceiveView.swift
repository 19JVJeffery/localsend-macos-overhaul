import SwiftUI
import LocalSendCore
import LocalSendUI

public struct IOSReceiveView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var accentColor: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LocalSendTheme.spacingLarge) {

                    // Active Incoming Transfers
                    let incoming = engine.activeTransfers.filter { $0.direction == .receiving }
                    if !incoming.isEmpty {
                        VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                            Text("Incoming Transfers")
                                .font(.headline)

                            ForEach(incoming) { session in
                                TransferProgressCard(session: session, accentColor: LocalSendTheme.success) {
                                    engine.cancelTransfer(id: session.id)
                                }
                            }
                        }
                    }

                    // Radar Beacon Card
                    VStack(spacing: LocalSendTheme.spacingMedium) {
                        RadarScanningView(isScanning: true, accentColor: accentColor)
                            .frame(width: 140, height: 140)

                        VStack(spacing: 4) {
                            HStack {
                                Text(engine.settings.alias)
                                    .font(.title2.weight(.bold))
                                Circle()
                                    .fill(LocalSendTheme.success)
                                    .frame(width: 8, height: 8)
                            }

                            Text("Ready to receive files on this network")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(LocalSendTheme.spacingLarge)
                    .background(LocalSendTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))

                    // Receive Settings Card
                    VStack(spacing: LocalSendTheme.spacingMedium) {
                        Toggle(isOn: $engine.settings.autoAccept) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Quick Save")
                                    .font(.headline)
                                Text("Automatically accept incoming transfers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(accentColor)
                        .onChange(of: engine.settings.autoAccept) { _ in
                            engine.settings.save()
                        }
                    }
                    .padding(LocalSendTheme.spacingMedium)
                    .background(LocalSendTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))

                    // Network IP info
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        Text("Network Information")
                            .font(.headline)

                        let ifaces = NetworkAddressHelper.getLocalIPv4Addresses()
                        if ifaces.isEmpty {
                            Text("No Wi-Fi connected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(ifaces, id: \.address) { iface in
                                HStack {
                                    Image(systemName: "wifi")
                                        .foregroundColor(accentColor)
                                    Text(iface.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(iface.address):\(engine.settings.port)")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(LocalSendTheme.spacingMedium)
                    .background(LocalSendTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))
                }
                .padding()
            }
            .navigationTitle("Receive")
            .tint(accentColor)
        }
    }
}
