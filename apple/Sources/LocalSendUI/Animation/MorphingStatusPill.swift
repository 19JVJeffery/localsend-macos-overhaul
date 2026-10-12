import SwiftUI
import LocalSendCore

public enum PillStatus: Equatable, Sendable {
    case idle
    case scanning
    case transferring(progress: Double)
    case completed
    case failed(reason: String?)
}

/// Adaptive status pill that morphs its shape, iconography, and colors based on transfer and network state.
public struct MorphingStatusPill: View {
    public let status: PillStatus
    public let accentColor: Color

    public init(status: PillStatus, accentColor: Color = LocalSendTheme.accent()) {
        self.status = status
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack(spacing: 8) {
            statusIcon
            statusLabel
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(pillBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(pillBorder, lineWidth: 1)
        )
        .animation(LocalSendMotion.smooth, value: status)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .idle:
            Circle()
                .fill(Color.secondary.opacity(0.6))
                .frame(width: 8, height: 8)
        case .scanning:
            TransferFlowView(isTransferring: true, accentColor: accentColor)
                .frame(width: 32)
        case .transferring(let progress):
            ProgressRingView(progress: progress, accentColor: accentColor, lineWidth: 2.5, size: 16)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(LocalSendTheme.success)
                .font(.system(size: 14))
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(LocalSendTheme.error)
                .font(.system(size: 14))
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch status {
        case .idle:
            Text("Ready")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        case .scanning:
            Text("Discovering Nearby")
                .font(.caption.weight(.medium))
                .foregroundColor(accentColor)
        case .transferring(let progress):
            Text("\(Int(progress * 100))%")
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundColor(.primary)
        case .completed:
            Text("Completed")
                .font(.caption.weight(.semibold))
                .foregroundColor(LocalSendTheme.success)
        case .failed(let reason):
            Text(reason ?? "Failed")
                .font(.caption.weight(.semibold))
                .foregroundColor(LocalSendTheme.error)
        }
    }

    private var pillBackground: Color {
        switch status {
        case .idle:
            return Color.secondary.opacity(0.1)
        case .scanning:
            return accentColor.opacity(0.12)
        case .transferring:
            return accentColor.opacity(0.12)
        case .completed:
            return LocalSendTheme.success.opacity(0.15)
        case .failed:
            return LocalSendTheme.error.opacity(0.15)
        }
    }

    private var pillBorder: Color {
        switch status {
        case .idle:
            return Color.secondary.opacity(0.15)
        case .scanning:
            return accentColor.opacity(0.3)
        case .transferring:
            return accentColor.opacity(0.4)
        case .completed:
            return LocalSendTheme.success.opacity(0.4)
        case .failed:
            return LocalSendTheme.error.opacity(0.4)
        }
    }
}
