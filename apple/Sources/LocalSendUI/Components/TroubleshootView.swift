import SwiftUI
import LocalSendCore

/// Comprehensive troubleshooting view diagnosing network and firewall issues,
/// providing direct resolution paths matching original LocalSend behavior.
public struct TroubleshootView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

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
                    // Header diagnosis banner
                    diagnosisBanner

                    // Network Configuration Overview
                    networkOverviewCard

                    // Troubleshooting Guides
                    guideCard(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Devices cannot discover each other",
                        subtitle: "Multicast discovery may be restricted on your current network.",
                        steps: [
                            "Ensure both devices are connected to the exact same Wi-Fi network or local subnet.",
                            "Check if your Wi-Fi router has 'AP Isolation', 'Client Isolation', or 'Guest Mode' enabled. If enabled, devices cannot communicate directly.",
                            "If using cellular hotspot or public Wi-Fi (such as hotel, airport, or university networks), peer-to-peer traffic is often blocked. Try connecting both devices to a personal mobile hotspot.",
                            "As an immediate workaround, use 'Send to IP' from the Send screen to connect directly using the recipient's IP address."
                        ],
                        actionTitle: "Use Send to IP",
                        actionIcon: "network",
                        action: nil
                    )

                    #if os(macOS)
                    guideCard(
                        icon: "shield.checkerboard",
                        title: "Incoming transfers blocked by macOS Firewall",
                        subtitle: "macOS Application Firewall or security software may block incoming traffic.",
                        steps: [
                            "LocalSend requires incoming TCP and UDP connections on port \(engine.settings.port).",
                            "Open macOS System Settings > Network > Firewall > Options, and ensure LocalSend is set to 'Allow incoming connections'.",
                            "Third-party network filters (such as Little Snitch, LuLu, or VPN software) may need a rule allowing traffic on port \(engine.settings.port)."
                        ],
                        actionTitle: "Open Firewall Settings",
                        actionIcon: "gearshape",
                        action: {
                            openFirewallSettings()
                        }
                    )
                    #endif

                    guideCard(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Transfers fail or stall midway",
                        subtitle: "Connection drops or TLS handshake failures.",
                        steps: [
                            "Keep LocalSend open in the foreground on both devices until transfer completes.",
                            "Ensure both devices have enough free disk space for the incoming files.",
                            "Verify that both sender and receiver are on LocalSend protocol v2 or later."
                        ],
                        actionTitle: nil,
                        actionIcon: nil,
                        action: nil
                    )
                }
                .padding(LocalSendTheme.spacingLarge)
            }
            .background(LocalSendTheme.windowBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
            .navigationTitle("Troubleshoot Connection")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 540, minHeight: 620)
        #endif
    }

    private var diagnosisBanner: some View {
        HStack(spacing: LocalSendTheme.spacingMedium) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title3)
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Network Diagnostics & Help")
                    .font(.headline)

                Text("LocalSend transfers files entirely over your local Wi-Fi network without third-party cloud servers or internet upload.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(LocalSendTheme.spacingMedium)
        .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
        )
    }

    private var networkOverviewCard: some View {
        VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
            Text("CURRENT NETWORK STATE")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            Divider()

            HStack {
                Label("Local IP Address", systemImage: "wifi")
                    .font(.subheadline)
                Spacer()
                Text(engine.localIPAddresses.first ?? "127.0.0.1")
                    .font(.subheadline.monospaced())
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("Local Server Port", systemImage: "network")
                    .font(.subheadline)
                Spacer()
                Text("\(engine.settings.port)")
                    .font(.subheadline.monospaced())
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("Multicast Discovery", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.subheadline)
                Spacer()
                Text("224.0.0.167:53317 (v2.2)")
                    .font(.subheadline.monospaced())
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("Device Alias", systemImage: "person.crop.circle")
                    .font(.subheadline)
                Spacer()
                Text(engine.settings.alias)
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding(LocalSendTheme.spacingMedium)
        .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
        )
    }

    private func guideCard(
        icon: String,
        title: String,
        subtitle: String,
        steps: [String],
        actionTitle: String?,
        actionIcon: String?,
        action: (() -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: LocalSendTheme.spacingMedium) {
            HStack(spacing: LocalSendTheme.spacingSmall) {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption.weight(.bold))
                            .foregroundColor(accentColor)
                            .frame(width: 18, alignment: .leading)

                        Text(step)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }

            if let actionTitle = actionTitle, let actionIcon = actionIcon, let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: actionIcon)
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
                .padding(.top, 4)
            }
        }
        .padding(LocalSendTheme.spacingMedium)
        .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
        )
    }

    #if os(macOS)
    private func openFirewallSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Firewall") {
            NSWorkspace.shared.open(url)
        }
    }
    #endif
}
