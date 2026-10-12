import SwiftUI
import LocalSendCore

/// AirDrop-inspired card displaying a discovered peer device.
public struct DeviceCard: View {
    public let device: Device
    public let isSelected: Bool
    public let onSend: () -> Void

    public init(device: Device, isSelected: Bool = false, onSend: @escaping () -> Void) {
        self.device = device
        self.isSelected = isSelected
        self.onSend = onSend
    }

    public var body: some View {
        Button(action: onSend) {
            VStack(spacing: LocalSendTheme.spacingSmall) {
                // Device Icon with circular background
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: device.deviceType.systemImageName)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.accentColor)
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
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .frame(minWidth: 120, maxWidth: 160)
            .padding(LocalSendTheme.spacingMedium)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : LocalSendTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
