import SwiftUI
import LocalSendCore
import LocalSendUI

/// Modal sheet shown when another device requests to send files.
public struct MacReceiveModal: View {
    public let session: TransferSession
    public let onAccept: () -> Void
    public let onDecline: () -> Void

    public init(session: TransferSession, onAccept: @escaping () -> Void, onDecline: @escaping () -> Void) {
        self.session = session
        self.onAccept = onAccept
        self.onDecline = onDecline
    }

    public var body: some View {
        VStack(spacing: LocalSendTheme.spacingLarge) {
            // Icon & Header
            VStack(spacing: LocalSendTheme.spacingSmall) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 64, height: 64)

                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                }

                Text("Incoming Transfer Request")
                    .font(.title2.weight(.bold))

                Text("\(session.remoteDevice.alias) wants to send you \(session.files.count) file\(session.files.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // File list preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Files (\(LocalSendFormatters.formatFileSize(session.totalSize)))")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(session.files) { item in
                            HStack {
                                Image(systemName: "doc")
                                    .foregroundColor(.secondary)
                                Text(item.fileName)
                                    .font(.body)
                                    .lineLimit(1)
                                Spacer()
                                Text(LocalSendFormatters.formatFileSize(item.size))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxHeight: 140)
            }
            .padding(LocalSendTheme.spacingMedium)
            .background(LocalSendTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))

            // Action Buttons
            HStack(spacing: LocalSendTheme.spacingMedium) {
                Button("Decline", action: onDecline)
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Accept", action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(LocalSendTheme.spacingLarge)
        .frame(width: 440)
    }
}
