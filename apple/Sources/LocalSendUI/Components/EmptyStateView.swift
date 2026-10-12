import SwiftUI

public struct EmptyStateView: View {
    public let iconName: String
    public let title: String
    public let message: String
    public let actionTitle: String?
    public let onAction: (() -> Void)?

    public init(
        iconName: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    public var body: some View {
        VStack(spacing: LocalSendTheme.spacingMedium) {
            Image(systemName: iconName)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary.opacity(0.8))

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, LocalSendTheme.spacingSmall)
            }
        }
        .padding(LocalSendTheme.spacingExtraLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
