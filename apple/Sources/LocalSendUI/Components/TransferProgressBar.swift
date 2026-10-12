import SwiftUI
import LocalSendCore

/// Card view representing an in-flight or completed transfer session with animated progress bar,
/// dynamic data stream pulses, and refined status indicators.
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
        let activeColor = session.direction == .sending ? accentColor : LocalSendTheme.success

        VStack(alignment: .leading, spacing: LocalSendTheme.spacingSmall) {
            // Header: Direction + Device + File count
            HStack(spacing: LocalSendTheme.spacingSmall) {
                ZStack {
                    Circle()
                        .fill(activeColor.opacity(0.15))
                        .frame(width: 38, height: 38)

                    Image(systemName: session.direction == .sending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(activeColor)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(session.direction == .sending ? "Sending to \(session.remoteDevice.alias)" : "Receiving from \(session.remoteDevice.alias)")
                            .font(.headline)

                        if !session.status.isTerminal {
                            TransferFlowView(isTransferring: true, accentColor: activeColor, particleCount: 4)
                        }
                    }

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
                    accentColor: activeColor,
                    height: 8
                )

                HStack {
                    HStack(spacing: 4) {
                        Text("\(Int(session.progress * 100))%")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundColor(.primary)

                        if session.status == .inProgress {
                            Text("• Transferring")
                                .font(.caption2)
                                .foregroundColor(activeColor)
                        }
                    }

                    Spacer()

                    Text("\(LocalSendFormatters.formatFileSize(session.transferredSize)) of \(LocalSendFormatters.formatFileSize(session.totalSize))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Error message if failed
            if let error = session.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(LocalSendTheme.error)
                .padding(.top, 2)
            }
        }
        .padding(LocalSendTheme.spacingMedium)
        .background(LocalSendTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                .stroke(
                    !session.status.isTerminal
                        ? activeColor.opacity(0.25)
                        : LocalSendTheme.borderSubtle,
                    lineWidth: 1
                )
        )
        .localSendShadow(LocalSendTheme.shadowSubtle)
        .animation(LocalSendMotion.standard, value: session.progress)
        .animation(LocalSendMotion.standard, value: session.status)
    }
}
