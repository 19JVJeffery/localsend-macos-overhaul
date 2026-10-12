import SwiftUI
import LocalSendCore

/// Toast payload definition for notifications and quick HUD feedback.
public struct ToastItem: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let message: String?
    public let systemImage: String
    public let tint: Color
    public let duration: TimeInterval

    public init(
        title: String,
        message: String? = nil,
        systemImage: String = "checkmark.circle.fill",
        tint: Color = LocalSendTheme.success,
        duration: TimeInterval = 2.2
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.tint = tint
        self.duration = duration
    }

    public static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Floating Island HUD Toast inspired by SPAlert and AlertToast.
/// Features frosted glass styling, spring entrance, and auto-dismissal.
public struct FloatingToastView: View {
    public let toast: ToastItem
    public let onDismiss: () -> Void

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(toast.tint)

            VStack(alignment: .leading, spacing: 1) {
                Text(toast.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                if let msg = toast.message, !msg.isEmpty {
                    Text(msg)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 4)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(LocalSendTheme.cardBackground.opacity(0.92))
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            toast.tint.opacity(0.4),
                            toast.tint.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .localSendShadow(LocalSendTheme.shadowMedium)
        .contentShape(Capsule())
        .onTapGesture {
            onDismiss()
        }
    }
}

/// Toast presentation modifier.
public struct ToastModifier: ViewModifier {
    @Binding var toast: ToastItem?

    public func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let currentToast = toast {
                FloatingToastView(toast: currentToast) {
                    withAnimation(LocalSendMotion.snappy) {
                        toast = nil
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: 360)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
                .zIndex(999)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + currentToast.duration) {
                        if toast?.id == currentToast.id {
                            withAnimation(LocalSendMotion.snappy) {
                                toast = nil
                            }
                        }
                    }
                }
            }
        }
        .animation(LocalSendMotion.bouncy, value: toast)
    }
}

public extension View {
    /// Present a floating toast HUD whenever a ToastItem is assigned.
    func localSendToast(_ toast: Binding<ToastItem?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
