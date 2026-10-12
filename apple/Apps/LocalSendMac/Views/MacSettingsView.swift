import SwiftUI
import AppKit
import LocalSendCore
import LocalSendUI

public struct MacSettingsView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowcasePresented = false
    @State private var isTroubleshootPresented = false
    @State private var isAboutPresented = false

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var currentAccent: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LocalSendTheme.spacingLarge) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings")
                        .font(.title2.weight(.bold))
                    Text("Preferences, appearance, and network configuration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 1. Appearance & Palette Section
                settingsCard(title: "APPEARANCE & PALETTE") {
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingMedium) {
                        // Theme Mode (System / Light / Dark)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Theme")
                                .font(.subheadline.weight(.semibold))

                            Picker("Theme Mode", selection: $engine.settings.themeMode) {
                                ForEach(ThemeModePreference.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: engine.settings.themeMode) { _ in
                                engine.settings.save()
                            }
                        }

                        Divider()

                        // Accent Color Preference
                        VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                            Text("Accent Colour")
                                .font(.subheadline.weight(.semibold))

                            HStack(spacing: LocalSendTheme.spacingMedium) {
                                accentOptionCard(
                                    preference: .localSend,
                                    title: "Original LocalSend",
                                    subtitle: "Signature Teal (#008080 / #009688)",
                                    color: colorScheme == .dark ? LocalSendTheme.Brand.teal300 : LocalSendTheme.Brand.teal700
                                )

                                accentOptionCard(
                                    preference: .system,
                                    title: "Match System Accent",
                                    subtitle: "Follows macOS System Settings",
                                    color: Color(nsColor: .controlAccentColor)
                                )
                            }
                        }
                    }
                }

                // 2. Device Identification
                settingsCard(title: "DEVICE IDENTIFICATION") {
                    VStack(spacing: LocalSendTheme.spacingSmall) {
                        HStack {
                            Text("Device Name")
                                .font(.subheadline)
                            Spacer()
                            TextField("Device Name", text: $engine.settings.alias)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 260)
                                .onChange(of: engine.settings.alias) { _ in
                                    engine.settings.save()
                                }
                        }

                        Divider()

                        HStack {
                            Text("Device Type")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $engine.settings.deviceType) {
                                ForEach(DeviceType.allCases, id: \.self) { type in
                                    Label(type.displayName, systemImage: type.systemImageName).tag(type)
                                }
                            }
                            .frame(width: 260)
                            .onChange(of: engine.settings.deviceType) { _ in
                                engine.settings.save()
                            }
                        }
                    }
                }

                // 3. Network & Protocol
                settingsCard(title: "NETWORK & PROTOCOL") {
                    VStack(spacing: LocalSendTheme.spacingSmall) {
                        HStack {
                            Text("Server Port")
                                .font(.subheadline)
                            Spacer()
                            TextField("Port", value: $engine.settings.port, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 260)
                                .onChange(of: engine.settings.port) { _ in
                                    engine.settings.save()
                                }
                        }

                        Divider()

                        HStack {
                            Text("Protocol Encryption")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $engine.settings.protocolType) {
                                Text("HTTP (Standard)").tag(ProtocolType.http)
                                Text("HTTPS (Encrypted)").tag(ProtocolType.https)
                            }
                            .frame(width: 260)
                            .onChange(of: engine.settings.protocolType) { _ in
                                engine.settings.save()
                            }
                        }

                        Divider()

                        HStack {
                            Text("Multicast Discovery Group")
                                .font(.subheadline)
                            Spacer()
                            TextField("Multicast Group", text: $engine.settings.multicastGroup)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 260)
                                .onChange(of: engine.settings.multicastGroup) { _ in
                                    engine.settings.save()
                                }
                        }
                    }
                }

                // 4. File Transfers
                settingsCard(title: "FILE TRANSFERS") {
                    VStack(spacing: LocalSendTheme.spacingSmall) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Destination Folder")
                                    .font(.subheadline)
                                Text(engine.settings.destinationDirectoryPath)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button("Browse...") {
                                chooseFolder()
                            }
                            .buttonStyle(.bordered)
                        }

                        Divider()

                        Toggle("Quick Save (Auto-Accept Transfers)", isOn: $engine.settings.autoAccept)
                            .onChange(of: engine.settings.autoAccept) { _ in
                                engine.settings.save()
                            }

                        Divider()

                        Toggle("Save to Transfer History", isOn: $engine.settings.saveToHistory)
                            .onChange(of: engine.settings.saveToHistory) { _ in
                                engine.settings.save()
                            }
                    }
                }

                // 5. Help, Diagnostics & About
                settingsCard(title: "HELP & DIAGNOSTICS") {
                    VStack(spacing: LocalSendTheme.spacingSmall) {
                        Button(action: { isTroubleshootPresented = true }) {
                            HStack {
                                Label("Troubleshoot Connection...", systemImage: "wrench.and.screwdriver")
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)

                        Divider()

                        Button(action: { isAboutPresented = true }) {
                            HStack {
                                Label("About LocalSend...", systemImage: "info.circle")
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)

                        Divider()

                        Button(action: { isShowcasePresented = true }) {
                            HStack {
                                Label("Design & Animation Showcase...", systemImage: "sparkles")
                                    .font(.subheadline)
                                    .foregroundColor(currentAccent)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(LocalSendTheme.spacingLarge)
        }
        .background(LocalSendTheme.windowBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
        .sheet(isPresented: $isShowcasePresented) {
            DeveloperShowcaseView(engine: engine)
        }
        .sheet(isPresented: $isTroubleshootPresented) {
            TroubleshootView(engine: engine)
        }
        .sheet(isPresented: $isAboutPresented) {
            AboutView(engine: engine)
        }
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                content()
            }
            .padding(LocalSendTheme.spacingMedium)
            .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                    .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
            )
        }
    }

    private func accentOptionCard(
        preference: AccentColorPreference,
        title: String,
        subtitle: String,
        color: Color
    ) -> some View {
        let isSelected = engine.settings.accentColorPreference == preference

        return Button(action: {
            withAnimation(LocalSendMotion.snappy) {
                engine.settings.accentColorPreference = preference
                engine.settings.save()
            }
        }) {
            HStack(spacing: LocalSendTheme.spacingSmall) {
                Circle()
                    .fill(color)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: isSelected ? 2 : 0)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(currentAccent)
                        .font(.headline)
                }
            }
            .padding(LocalSendTheme.spacingSmall)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusSmall, style: .continuous)
                    .fill(isSelected ? currentAccent.opacity(0.12) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusSmall, style: .continuous)
                    .stroke(isSelected ? currentAccent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func chooseFolder() {
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
