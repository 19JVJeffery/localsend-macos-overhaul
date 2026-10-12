import SwiftUI
import LocalSendCore

/// Developer-oriented motion and design-system showcase for testing and tuning animations.
public struct DeveloperShowcaseView: View {
    @State private var colorPreference: AccentColorPreference = .localSend
    @State private var sampleProgress: Double = 0.45
    @State private var isScanning = true
    @State private var pillStatus: PillStatus = .transferring(progress: 0.45)
    @State private var showCelebration = false
    @Environment(\.colorScheme) private var colorScheme

    public init(engine: LocalSendEngine? = nil) {
        if let engine = engine {
            _colorPreference = State(initialValue: engine.settings.accentColorPreference)
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LocalSendTheme.spacingLarge) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Design System & Motion Showcase")
                        .font(.title2.weight(.bold))
                    Text("Interactive test harness to preview and calibrate colors, springs, and particles.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                // 1. Accent Color Switcher
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    Text("Accent Color Palette")
                        .font(.headline)

                    Picker("Palette", selection: $colorPreference) {
                        ForEach(AccentColorPreference.allCases, id: \.self) { pref in
                            Text(pref.displayName).tag(pref)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: LocalSendTheme.spacingMedium) {
                        colorSwatch("Primary Accent", color: LocalSendTheme.accent(for: colorPreference, colorScheme: colorScheme))
                        colorSwatch("Container", color: LocalSendTheme.accentContainer(for: colorPreference, colorScheme: colorScheme))
                        colorSwatch("Success", color: LocalSendTheme.success)
                        colorSwatch("Warning", color: LocalSendTheme.warning)
                        colorSwatch("Error", color: LocalSendTheme.error)
                    }
                }
                .localSendCardStyle()

                // 2. Radar Scanning Animation
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    HStack {
                        Text("Device Discovery Radar")
                            .font(.headline)
                        Spacer()
                        Toggle("Scanning", isOn: $isScanning)
                            .toggleStyle(.switch)
                    }

                    HStack {
                        Spacer()
                        RadarScanningView(isScanning: isScanning, accentColor: LocalSendTheme.accent(for: colorPreference, colorScheme: colorScheme))
                        Spacer()
                    }
                }
                .localSendCardStyle()

                // 3. Shape Morphing Status Pill
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    Text("Shape Morphing Status Pill")
                        .font(.headline)

                    HStack {
                        MorphingStatusPill(status: pillStatus, accentColor: LocalSendTheme.accent(for: colorPreference, colorScheme: colorScheme))
                        Spacer()
                    }

                    HStack(spacing: 8) {
                        Button("Idle") { pillStatus = .idle }
                        Button("Scanning") { pillStatus = .scanning }
                        Button("Transfer (45%)") { pillStatus = .transferring(progress: 0.45) }
                        Button("Complete") { pillStatus = .completed }
                        Button("Failed") { pillStatus = .failed(reason: "Rejected") }
                    }
                    .buttonStyle(.bordered)
                }
                .localSendCardStyle()

                // 4. Modern Transfer Progress Bar
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    Text("Transfer Progress Bar")
                        .font(.headline)

                    ModernProgressBar(
                        progress: sampleProgress,
                        accentColor: LocalSendTheme.accent(for: colorPreference, colorScheme: colorScheme),
                        height: 10
                    )

                    Slider(value: $sampleProgress, in: 0.0...1.0) {
                        Text("Progress")
                    }

                    HStack {
                        Text("Progress: \(Int(sampleProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        ProgressRingView(
                            progress: sampleProgress,
                            accentColor: LocalSendTheme.accent(for: colorPreference, colorScheme: colorScheme),
                            size: 40
                        )
                    }
                }
                .localSendCardStyle()

                // 5. Success Celebration Burst
                VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                    HStack {
                        Text("Success Particle Celebration")
                            .font(.headline)
                        Spacer()
                        Button("Trigger Burst") {
                            showCelebration = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                showCelebration = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if showCelebration {
                        HStack {
                            Spacer()
                            SuccessCelebrationView {
                                // burst completed
                            }
                            Spacer()
                        }
                    }
                }
                .localSendCardStyle()
            }
            .padding(LocalSendTheme.spacingLarge)
        }
    }

    private func colorSwatch(_ title: String, color: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 44, height: 32)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
