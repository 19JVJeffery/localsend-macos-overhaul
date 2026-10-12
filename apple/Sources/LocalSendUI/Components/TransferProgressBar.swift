import SwiftUI
import LocalSendCore

/// Card view representing an in-flight or completed transfer session with progress bar and controls.
public struct TransferProgressCard: View {
    public let session: TransferSession
    public let onCancel: () -> Void

    public init(session: TransferSession, onCancel: @escaping () -> Void) {
        self.session = session
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
            // Header: Remote device + Direction + Status
            HStack {
                Image(systemName: session.direction == .sending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(session.direction == .sending ? .accentColor : .green)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.direction == .sending ? "Sending to \(session.remoteDevice.alias)" : "Receiving from \(session.remoteDevice.alias)")
                        .font(.headline)

                    Text("\(session.files.count) file\(session.files.count == 1 ? "" : "s") • \(LocalSendFormatters.formatFileSize(session.totalSize))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !session.status.isTerminal {
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Cancel Transfer")
                } else {
                    StatusBadge(status: session.status)
                }
            }

            // Progress Bar
            if !session.status.isTerminal {
                ProgressView(value: session.progress, total: 1.0)
                    .progressViewStyle(.linear)

                HStack {
                    Text("\(Int(session.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(LocalSendFormatters.formatFileSize(session.transferredSize)) of \(LocalSendFormatters.formatFileSize(session.totalSize))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Error message if any
            if let error = session.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(LocalSendTheme.spacingMedium)
        .background(LocalSendTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
    }
}
