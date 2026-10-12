import SwiftUI
import LocalSendCore
import LocalSendUI

public struct IOSSettingsView: View {
    @ObservedObject var engine: LocalSendEngine

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Device Identification") {
                    TextField("Device Name", text: $engine.settings.alias)

                    Picker("Device Type", selection: $engine.settings.deviceType) {
                        ForEach(DeviceType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.systemImageName).tag(type)
                        }
                    }
                }

                Section("Network") {
                    HStack {
                        Text("Port")
                        Spacer()
                        Text("\(engine.settings.port)")
                            .foregroundColor(.secondary)
                    }

                    Picker("Protocol", selection: $engine.settings.protocolType) {
                        Text("HTTP").tag(ProtocolType.http)
                        Text("HTTPS").tag(ProtocolType.https)
                    }
                }

                Section("Transfers") {
                    Toggle("Quick Save (Auto-Accept)", isOn: $engine.settings.autoAccept)
                    Toggle("Save to Transfer History", isOn: $engine.settings.saveToHistory)
                }

                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        engine.settings = AppSettings()
                        engine.settings.save()
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: engine.settings.alias) { _ in engine.settings.save() }
            .onChange(of: engine.settings.deviceType) { _ in engine.settings.save() }
            .onChange(of: engine.settings.autoAccept) { _ in engine.settings.save() }
            .onChange(of: engine.settings.saveToHistory) { _ in engine.settings.save() }
        }
    }
}
