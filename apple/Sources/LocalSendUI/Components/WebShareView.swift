import SwiftUI
import LocalSendCore

/// Web Share mode view allowing users on any platform or web browser
/// on the local Wi-Fi to download files without installing the LocalSend app.
public struct WebShareView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    @State private var webPin: String = ""

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    private var accentColor: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    private var shareURL: String {
        let ip = engine.localIPAddresses.first ?? "127.0.0.1"
        return "http://\(ip):\(engine.settings.port)"
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LocalSendTheme.spacingLarge) {
                    // Header Banner
                    HStack(spacing: LocalSendTheme.spacingMedium) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: "globe")
                                .font(.title3)
                                .foregroundColor(accentColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Browser Share Link")
                                .font(.headline)

                            Text("Anyone on your Wi-Fi can open this link in any browser (Safari, Chrome, Firefox) to download files.")
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

                    // URL Card with Copy
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        Text("SHARE URL")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        HStack {
                            Text(shareURL)
                                .font(.headline.monospaced())
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            Button(action: copyToClipboard) {
                                HStack(spacing: 4) {
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    Text(copied ? "Copied" : "Copy")
                                }
                                .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(copied ? LocalSendTheme.success : accentColor)
                        }
                        .padding(LocalSendTheme.spacingMedium)
                        .background(LocalSendTheme.accentContainer(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
                    }
                    .padding(LocalSendTheme.spacingMedium)
                    .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                            .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
                    )

                    // Staged files count
                    VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
                        Text("FILES OFFERED FOR DOWNLOAD")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        if engine.stagedFiles.isEmpty {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                Text("No files currently staged. Add files on the Send screen to share them.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        } else {
                            ForEach(engine.stagedFiles) { file in
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(accentColor)
                                    Text(file.name)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(LocalSendFormatters.formatFileSize(file.size))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding(LocalSendTheme.spacingMedium)
                    .background(LocalSendTheme.cardBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                            .stroke(LocalSendTheme.cardBorder(for: engine.settings.accentColorPreference, colorScheme: colorScheme), lineWidth: 1)
                    )

                    #if os(macOS)
                    Button(action: {
                        if let url = URL(string: shareURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Label("Open in Web Browser", systemImage: "arrow.up.forward.app")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    #endif
                }
                .padding(LocalSendTheme.spacingLarge)
            }
            .background(LocalSendTheme.windowBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
            .navigationTitle("Web Share")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 460)
        #endif
    }

    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(shareURL, forType: .string)
        #else
        UIPasteboard.general.string = shareURL
        #endif
        withAnimation(LocalSendMotion.snappy) {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(LocalSendMotion.snappy) {
                copied = false
            }
        }
    }
}
