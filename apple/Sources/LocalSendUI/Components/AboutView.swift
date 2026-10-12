import SwiftUI
import LocalSendCore

/// Native Apple About view honoring the official LocalSend project,
/// creator Tien Do Nam, and open-source documentation.
public struct AboutView: View {
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
                    // App Identity Header
                    VStack(spacing: LocalSendTheme.spacingSmall) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(LocalSendTheme.Brand.teal700)
                                .frame(width: 88, height: 88)
                                .localSendShadow(LocalSendTheme.shadowMedium)

                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }

                        Text("LocalSend")
                            .font(.title.weight(.bold))

                        Text("Version 2.0 (Apple Native) • Protocol v2.2")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("An open-source cross-platform alternative to AirDrop.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.top, LocalSendTheme.spacingMedium)

                    // Quick Links Card
                    VStack(spacing: 0) {
                        linkRow(
                            title: "Official Website",
                            subtitle: "localsend.org",
                            icon: "globe",
                            urlString: "https://localsend.org"
                        )

                        Divider()

                        linkRow(
                            title: "Source Code on GitHub",
                            subtitle: "github.com/localsend/localsend",
                            icon: "chevron.left.forwardslash.chevron.right",
                            urlString: "https://github.com/localsend/localsend"
                        )

                        Divider()

                        linkRow(
                            title: "Protocol Specification",
                            subtitle: "github.com/localsend/protocol",
                            icon: "doc.text",
                            urlString: "https://github.com/localsend/protocol"
                        )
                    }
                    .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                            .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
                    )

                    // Project Credits
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        Text("CREDITS & AUTHOR")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        Divider()

                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(accentColor)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tien Do Nam (@Tienisto)")
                                    .font(.subheadline.weight(.semibold))
                                Text("Original Creator & Lead Developer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }

                        Divider()

                        Text("LocalSend is free and open-source software released under the MIT License. It does not contain tracking, analytics, or ads.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(LocalSendTheme.spacingMedium)
                    .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                            .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
                    )
                }
                .padding(LocalSendTheme.spacingLarge)
            }
            .background(LocalSendTheme.windowBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
            .navigationTitle("About LocalSend")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 520)
        #endif
    }

    private func linkRow(title: String, subtitle: String, icon: String, urlString: String) -> some View {
        Button(action: {
            if let url = URL(string: urlString) {
                #if os(macOS)
                NSWorkspace.shared.open(url)
                #else
                UIApplication.shared.open(url)
                #endif
            }
        }) {
            HStack(spacing: LocalSendTheme.spacingMedium) {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .font(.body)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, LocalSendTheme.spacingMedium)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
