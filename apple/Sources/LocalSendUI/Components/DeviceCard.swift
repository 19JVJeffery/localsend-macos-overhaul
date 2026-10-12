import SwiftUI
import LocalSendCore

/// Polished AirDrop-inspired card displaying a discovered peer device with hover and spring feedback.
public struct DeviceCard: View {
    public let device: Device
    public let isSelected: Bool
    public let accentColor: Color
    public let onSend: () -> Void

    @State private var isHovered = false

    public init(
        device: Device,
        isSelected: Bool = false,
        accentColor: Color = LocalSendTheme.accent(),
        onSend: @escaping () -> Void
    ) {
        self.device = device
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.onSend = onSend
    }

    public var body: some View {
        Button(action: onSend) {
            VStack(spacing: LocalSendTheme.spacingSmall) {
                // Device Icon with animated background
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor : accentColor.opacity(isHovered ? 0.22 : 0.12))
                        .frame(width: 58, height: 58)

                    Image(systemName: device.deviceType.systemImageName)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(isSelected ? .white : accentColor)
                }
                .padding(.top, 4)

                // Device Alias
                Text(device.alias)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                // Device Model or Subtitle
                if let model = device.deviceModel, !model.isEmpty {
                    Text(model)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // IP / Network indicator
                Text(device.formattedAddress)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .frame(minWidth: 130, maxWidth: 170)
            .padding(LocalSendTheme.spacingMedium)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.12) : (isHovered ? LocalSendTheme.cardBackground.opacity(0.95) : LocalSendTheme.cardBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                    .stroke(
                        isSelected ? accentColor : (isHovered ? accentColor.opacity(0.4) : LocalSendTheme.borderSubtle),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .localSendShadow(isHovered ? LocalSendTheme.shadowMedium : LocalSendTheme.shadowSubtle)
            .animation(LocalSendMotion.snappy, value: isHovered)
            .animation(LocalSendMotion.snappy, value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
