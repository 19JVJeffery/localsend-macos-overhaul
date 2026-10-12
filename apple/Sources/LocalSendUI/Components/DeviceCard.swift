import SwiftUI
import LocalSendCore

/// Polished AirDrop-inspired card displaying a discovered peer device with glassmorphic depth,
/// live online indicator pulse, specular borders, and tactile spring feedback.
public struct DeviceCard: View {
    public let device: Device
    public let isSelected: Bool
    public let accentColor: Color
    public let onSend: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var onlinePulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        device: Device,
        isSelected: Bool = false,
        accentColor: Color = LocalSendTheme.accent(),
        onSend: @escaping VoidClosure
    ) {
        self.device = device
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.onSend = onSend
    }

    public typealias VoidClosure = () -> Void

    public var body: some View {
        Button(action: onSend) {
            VStack(spacing: LocalSendTheme.spacingSmall) {
                // Device Icon with nested glowing badge & live status dot
                ZStack(alignment: .topTrailing) {
                    // Outer glow halo on hover/selection
                    Circle()
                        .fill(isSelected ? accentColor.opacity(0.28) : (isHovered ? accentColor.opacity(0.18) : Color.clear))
                        .frame(width: 68, height: 68)
                        .blur(radius: 6)

                    // Frosted circular container
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(colors: [accentColor, accentColor.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [accentColor.opacity(isHovered ? 0.22 : 0.12), accentColor.opacity(isHovered ? 0.12 : 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 58, height: 58)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.white.opacity(0.4) : accentColor.opacity(0.25), lineWidth: 1)
                        )

                    // Device Glyph
                    Image(systemName: device.deviceType.systemImageName)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(isSelected ? .white : accentColor)
                        .frame(width: 58, height: 58)

                    // Live Online Status Micro-dot
                    ZStack {
                        if !reduceMotion {
                            Circle()
                                .stroke(LocalSendTheme.success.opacity(0.6), lineWidth: 1)
                                .frame(width: 14, height: 14)
                                .scaleEffect(onlinePulse ? 1.5 : 1.0)
                                .opacity(onlinePulse ? 0.0 : 0.8)
                        }

                        Circle()
                            .fill(LocalSendTheme.success)
                            .frame(width: 9, height: 9)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                    .offset(x: 2, y: 0)
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

                // IP / Network indicator pill
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.system(size: 9))
                    Text(device.formattedAddress)
                        .font(.system(size: 11, design: .monospaced))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.08))
                .clipShape(Capsule())
            }
            .frame(minWidth: 136, maxWidth: 176)
            .padding(LocalSendTheme.spacingMedium)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                    .fill(
                        isSelected
                            ? accentColor.opacity(0.14)
                            : (isHovered ? LocalSendTheme.cardBackground.opacity(0.96) : LocalSendTheme.cardBackground)
                    )
            )
            .overlay(
                // Specular & Accent Border
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(colors: [accentColor, accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(
                                colors: [
                                    isHovered ? accentColor.opacity(0.45) : LocalSendTheme.borderSubtle,
                                    isHovered ? accentColor.opacity(0.15) : LocalSendTheme.borderSubtle.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.025 : 1.0))
            .localSendShadow(isSelected ? LocalSendTheme.shadowAccentGlow : (isHovered ? LocalSendTheme.shadowMedium : LocalSendTheme.shadowSubtle))
            .animation(LocalSendMotion.bouncy, value: isHovered)
            .animation(LocalSendMotion.snappy, value: isSelected)
            .animation(LocalSendMotion.snappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                    onlinePulse = true
                }
            }
        }
    }
}
