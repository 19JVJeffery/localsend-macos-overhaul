import SwiftUI
import LocalSendCore
import LocalSendUI

public struct IOSSettingsView: View {
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
        NavigationStack {
            Form {
                // Theme & Accent Color
                Section("Appearance & Palette") {
                    Picker("Theme", selection: $engine.settings.themeMode) {
                        ForEach(ThemeModePreference.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Accent Colour", selection: $engine.settings.accentColorPreference) {
                        ForEach(AccentColorPreference.allCases, id: \.self) { pref in
                            Text(pref.displayName).tag(pref)
                        }
                    }

                    HStack {
                        Circle()
                            .fill(currentAccent)
                            .frame(width: 20, height: 20)

                        Text(engine.settings.accentColorPreference.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Device Info
                Section("Device Identification") {
                    TextField("Device Name", text: $engine.settings.alias)

                    Picker("Device Type", selection: $engine.settings.deviceType) {
                        ForEach(DeviceType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.systemImageName).tag(type)
                        }
                    }
                }

                // Network
                Section("Network") {
                    HStack {
                        Text("Port")
                        Spacer()
                        Text("\(engine.settings.port)")
                            .foregroundColor(.secondary)
                    }

                    Picker("Protocol", selection: $engine.settings.protocolType) {
                        Text("HTTP (Standard)").tag(ProtocolType.http)
                        Text("HTTPS (Encrypted)").tag(ProtocolType.https)
                    }
                }

                // Transfers
                Section("Transfers") {
                    Toggle("Quick Save (Auto-Accept)", isOn: $engine.settings.autoAccept)
                    Toggle("Save to Transfer History", isOn: $engine.settings.saveToHistory)
                }

                // Help & About
                Section("Help & Information") {
                    Button(action: { isTroubleshootPresented = true }) {
                        Label("Troubleshoot Connection...", systemImage: "wrench.and.screwdriver")
                            .foregroundColor(.primary)
                    }

                    Button(action: { isAboutPresented = true }) {
                        Label("About LocalSend...", systemImage: "info.circle")
                            .foregroundColor(.primary)
                    }

                    Button(action: { isShowcasePresented = true }) {
                        Label("Animation & Motion Showcase...", systemImage: "sparkles")
                            .foregroundColor(currentAccent)
                    }
                }

                // Reset
                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        withAnimation(LocalSendMotion.snappy) {
                            engine.settings = AppSettings()
                            engine.settings.save()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .tint(currentAccent)
            .sheet(isPresented: $isShowcasePresented) {
                NavigationStack {
                    DeveloperShowcaseView(engine: engine)
                        .navigationTitle("Showcase")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { isShowcasePresented = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $isTroubleshootPresented) {
                TroubleshootView(engine: engine)
            }
            .sheet(isPresented: $isAboutPresented) {
                AboutView(engine: engine)
            }
            .onChange(of: engine.settings.alias) { _ in engine.settings.save() }
            .onChange(of: engine.settings.deviceType) { _ in engine.settings.save() }
            .onChange(of: engine.settings.autoAccept) { _ in engine.settings.save() }
            .onChange(of: engine.settings.saveToHistory) { _ in engine.settings.save() }
            .onChange(of: engine.settings.accentColorPreference) { _ in engine.settings.save() }
            .onChange(of: engine.settings.themeMode) { _ in engine.settings.save() }
        }
    }
}
