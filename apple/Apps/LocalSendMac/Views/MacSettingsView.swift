import SwiftUI
import AppKit
import LocalSendCore
import LocalSendUI

public struct MacSettingsView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowcasePresented = false

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var currentAccent: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    public var body: some View {
        Form {
            // 1. Appearance & Accent Color Section
            Section("Appearance & Palette") {
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    Text("Accent Colour")
                        .font(.headline)

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
                .padding(.vertical, 4)
            }

            // 2. Device Identification
            Section("Device Identification") {
                TextField("Device Name", text: $engine.settings.alias)
                    .textFieldStyle(.roundedBorder)

                Picker("Device Type", selection: $engine.settings.deviceType) {
                    ForEach(DeviceType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.systemImageName).tag(type)
                    }
                }
            }

            // 3. Network & Protocol
            Section("Network & Protocol") {
                TextField("Server Port", value: $engine.settings.port, format: .number)
                    .textFieldStyle(.roundedBorder)

                Picker("Protocol", selection: $engine.settings.protocolType) {
                    Text("HTTP (Standard)").tag(ProtocolType.http)
                    Text("HTTPS (Encrypted)").tag(ProtocolType.https)
                }

                TextField("Multicast Group", text: $engine.settings.multicastGroup)
                    .textFieldStyle(.roundedBorder)
            }

            // 4. File Transfers
            Section("File Transfers") {
                HStack {
                    TextField("Destination Directory", text: $engine.settings.destinationDirectoryPath)
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)

                    Button("Browse...") {
                        chooseFolder()
                    }
                }

                Toggle("Auto-Accept Transfers", isOn: $engine.settings.autoAccept)
                Toggle("Save to Transfer History", isOn: $engine.settings.saveToHistory)
            }

            // 5. Developer & Motion Showcase
            Section("Motion & Visual Design") {
                Button(action: { isShowcasePresented = true }) {
                    Label("Open Animation & Motion Showcase...", systemImage: "sparkles")
                        .foregroundColor(currentAccent)
                }
            }

            // 6. Reset
            Section {
                Button("Reset to Defaults", role: .destructive) {
                    withAnimation(LocalSendMotion.snappy) {
                        engine.settings = AppSettings()
                        engine.settings.save()
                    }
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .padding(LocalSendTheme.spacingLarge)
        .sheet(isPresented: $isShowcasePresented) {
            VStack {
                HStack {
                    Spacer()
                    Button("Done") { isShowcasePresented = false }
                        .keyboardShortcut(.defaultAction)
                        .padding([.top, .trailing])
                }
                DeveloperShowcaseView()
            }
            .frame(minWidth: 540, minHeight: 600)
        }
        .onChange(of: engine.settings.alias) { _ in engine.settings.save() }
        .onChange(of: engine.settings.deviceType) { _ in engine.settings.save() }
        .onChange(of: engine.settings.port) { _ in engine.settings.save() }
        .onChange(of: engine.settings.protocolType) { _ in engine.settings.save() }
        .onChange(of: engine.settings.autoAccept) { _ in engine.settings.save() }
        .onChange(of: engine.settings.saveToHistory) { _ in engine.settings.save() }
        .onChange(of: engine.settings.accentColorPreference) { _ in engine.settings.save() }
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
            HStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                        .font(.title3)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                    .fill(isSelected ? color.opacity(0.12) : LocalSendTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                    .stroke(isSelected ? color : LocalSendTheme.borderSubtle, lineWidth: isSelected ? 2 : 1)
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
        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            engine.settings.destinationDirectoryPath = selectedURL.path
            engine.settings.save()
        }
    }
}
