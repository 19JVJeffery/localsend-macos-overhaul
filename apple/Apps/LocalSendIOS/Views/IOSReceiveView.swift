import SwiftUI
import LocalSendCore
import LocalSendUI

public struct IOSReceiveView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme
    @State private var copiedIP: String?
    @State private var isWebSharePresented = false
    @State private var toast: ToastItem?

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

                            Button(action: { isWebSharePresented = true }) {
                                Label("Open Web Share Mode", systemImage: "globe")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(accentColor)
                            .padding(.top, 4)
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
                    .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                            .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
                    )

                    // Network IP info
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        HStack {
                            Text("Network Information")
                                .font(.headline)
                            Spacer()
                            Text("Tap to copy")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        let ifaces = NetworkAddressHelper.getLocalIPv4Addresses()
                        if ifaces.isEmpty {
                            Text("No Wi-Fi connected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(ifaces, id: \.address) { iface in
                                Button(action: { copyIP(iface.address) }) {
                                    HStack {
                                        Image(systemName: "wifi")
                                            .foregroundColor(accentColor)
                                        Text(iface.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if copiedIP == iface.address {
                                            Text("Copied!")
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(LocalSendTheme.success)
                                        } else {
                                            Text("\(iface.address):\(engine.settings.port)")
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(LocalSendTheme.spacingMedium)
                    .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                            .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
                    )
                }
                .padding(LocalSendTheme.spacingMedium)
            }
            .background(AmbientBackgroundView(accentColor: accentColor))
            .navigationTitle("Receive")
            .tint(accentColor)
            .localSendToast($toast)
            .sheet(isPresented: $isWebSharePresented) {
                WebShareView(engine: engine)
            }
        }
    }

    private func copyIP(_ address: String) {
        UIPasteboard.general.string = address
        withAnimation(LocalSendMotion.snappy) {
            copiedIP = address
            toast = ToastItem(title: "IP Address Copied", message: address, systemImage: "doc.on.doc.fill", tint: accentColor)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(LocalSendMotion.snappy) {
                if copiedIP == address {
                    copiedIP = nil
                }
            }
        }
    }
}
