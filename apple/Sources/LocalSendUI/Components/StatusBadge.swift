import SwiftUI
import LocalSendCore

public struct StatusBadge: View {
    public let status: TransferStatus

    public init(status: TransferStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .completed: return .green
        case .inProgress: return .blue
        case .waitingForApproval: return .orange
        case .canceled: return .secondary
        case .failed: return .red
        }
    }
}
