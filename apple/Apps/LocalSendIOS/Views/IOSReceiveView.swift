import SwiftUI
import LocalSendCore
import LocalSendUI

public struct IOSReceiveView: View {
    @ObservedObject var engine: LocalSendEngine

    public init(engine: LocalSendEngine) {
        self.engine = engine
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
                                TransferProgressCard(session: session) {
                                    engine.cancelTransfer(id: session.id)
                                }
                            }
                        }
                    }

                    // Device Radar Card
                    VStack(spacing: LocalSendTheme.spacingMedium) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 90, height: 90)

                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                        }

                        VStack(spacing: 4) {
                            HStack {
                                Text(engine.settings.alias)
                                    .font(.title2.weight(.bold))
                                Circle()
                                    .fill(Color.green)
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
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))

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
                        .tint(.accentColor)
                        .onChange(of: engine.settings.autoAccept) { _ in
                            engine.settings.save()
                        }
                    }
                    .padding(LocalSendTheme.spacingMedium)
                    .background(LocalSendTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))

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
                                        .foregroundColor(.secondary)
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
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
                }
                .padding()
            }
            .navigationTitle("Receive")
        }
    }
}
