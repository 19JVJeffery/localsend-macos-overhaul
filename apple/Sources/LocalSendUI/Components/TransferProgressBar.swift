import SwiftUI
import LocalSendCore

/// Card view representing an in-flight or completed transfer session with animated progress bar and controls.
public struct TransferProgressCard: View {
    public let session: TransferSession
    public let accentColor: Color
    public let onCancel: () -> Void

    public init(
        session: TransferSession,
        accentColor: Color = LocalSendTheme.accent(),
        onCancel: @escaping () -> Void
    ) {
        self.session = session
        self.accentColor = accentColor
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
            // Header: Direction + Device + File count
            HStack {
                ZStack {
                    Circle()
                        .fill(session.direction == .sending ? accentColor.opacity(0.15) : LocalSendTheme.success.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: session.direction == .sending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(session.direction == .sending ? accentColor : LocalSendTheme.success)
                        .font(.system(size: 20))
                }

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
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Cancel Transfer")
                } else {
                    StatusBadge(status: session.status)
                }
            }

            // Animated Modern Progress Bar
            if !session.status.isTerminal {
                ModernProgressBar(
                    progress: session.progress,
                    accentColor: session.direction == .sending ? accentColor : LocalSendTheme.success,
                    height: 8
                )

                HStack {
                    Text("\(Int(session.progress * 100))%")
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(LocalSendFormatters.formatFileSize(session.transferredSize)) of \(LocalSendFormatters.formatFileSize(session.totalSize))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Error message if failed
            if let error = session.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(LocalSendTheme.error)
            }
        }
        .padding(LocalSendTheme.spacingMedium)
        .background(LocalSendTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                .stroke(LocalSendTheme.borderSubtle, lineWidth: 1)
        )
        .localSendShadow(LocalSendTheme.shadowSubtle)
        .animation(LocalSendMotion.standard, value: session.progress)
        .animation(LocalSendMotion.standard, value: session.status)
    }
}
