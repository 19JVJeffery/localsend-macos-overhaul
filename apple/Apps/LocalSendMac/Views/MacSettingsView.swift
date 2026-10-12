import SwiftUI
import AppKit
import LocalSendCore
import LocalSendUI

public struct MacSettingsView: View {
    @ObservedObject var engine: LocalSendEngine

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    public var body: some View {
        Form {
            Section("Device Identification") {
                TextField("Device Name", text: $engine.settings.alias)
                    .textFieldStyle(.roundedBorder)

                Picker("Device Type", selection: $engine.settings.deviceType) {
                    ForEach(DeviceType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.systemImageName).tag(type)
                    }
                }
            }

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

            Section {
                Button("Reset to Defaults") {
                    engine.settings = AppSettings()
                    engine.settings.save()
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .padding(LocalSendTheme.spacingLarge)
        .onChange(of: engine.settings.alias) { _ in engine.settings.save() }
        .onChange(of: engine.settings.deviceType) { _ in engine.settings.save() }
        .onChange(of: engine.settings.port) { _ in engine.settings.save() }
        .onChange(of: engine.settings.protocolType) { _ in engine.settings.save() }
        .onChange(of: engine.settings.autoAccept) { _ in engine.settings.save() }
        .onChange(of: engine.settings.saveToHistory) { _ in engine.settings.save() }
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
