import SwiftUI

/// Shared Apple Human Interface Guidelines theme constants and tokens.
public enum LocalSendTheme {
    // Corner Radii
    public static let cornerRadiusSmall: CGFloat = 8
    public static let cornerRadiusMedium: CGFloat = 12
    public static let cornerRadiusLarge: CGFloat = 16
    public static let cornerRadiusCard: CGFloat = 18

    // Padding & Spacing
    public static let spacingSmall: CGFloat = 8
    public static let spacingMedium: CGFloat = 16
    public static let spacingLarge: CGFloat = 24
    public static let spacingExtraLarge: CGFloat = 32

    // Shadows
    public static let shadowRadius: CGFloat = 6
    public static let shadowY: CGFloat = 2

    // Colors
    public static let accent = Color.accentColor
    public static let successGreen = Color.green
    public static let warningOrange = Color.orange
    public static let errorRed = Color.red

    #if os(macOS)
    public static let primaryBackground = Color(nsColor: .windowBackgroundColor)
    public static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
    public static let tertiaryBackground = Color(nsColor: .underPageBackgroundColor)
    public static let cardBackground = Color(nsColor: .unemphasizedSelectedContentBackgroundColor).opacity(0.15)
    #else
    public static let primaryBackground = Color(uiColor: .systemBackground)
    public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    public static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    #endif
}

public extension View {
    func localSendCardStyle() -> some View {
        self
            .padding(LocalSendTheme.spacingMedium)
            .background(LocalSendTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}
