import SwiftUI
import LocalSendCore
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Comprehensive design system tokens and semantic color engine for LocalSend Apple applications.
public enum LocalSendTheme {
    // MARK: - Spacing Scale
    public static let spacingXXS: CGFloat = 4
    public static let spacingXS: CGFloat = 8
    public static let spacingSmall: CGFloat = 12
    public static let spacingMedium: CGFloat = 16
    public static let spacingLarge: CGFloat = 24
    public static let spacingXL: CGFloat = 32
    public static let spacingExtraLarge: CGFloat = 32
    public static let spacingXXL: CGFloat = 48

    // MARK: - Corner Radii
    public static let cornerRadiusSmall: CGFloat = 8
    public static let cornerRadiusMedium: CGFloat = 12
    public static let cornerRadiusLarge: CGFloat = 16
    public static let cornerRadiusCard: CGFloat = 20
    public static let cornerRadiusPill: CGFloat = 999

    // MARK: - Shadows
    public static let shadowSubtle = ShadowToken(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    public static let shadowMedium = ShadowToken(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    public static let shadowElevated = ShadowToken(color: Color.black.opacity(0.14), radius: 20, x: 0, y: 8)
    public static let shadowAccentGlow = ShadowToken(color: Color.accentColor.opacity(0.25), radius: 12, x: 0, y: 4)

    // MARK: - Source-Verified LocalSend Brand Colors
    /// The canonical LocalSend teal palette verified from official source (theme.dart & logo.png).
    public enum Brand {
        public static let teal500 = Color(red: 0x00 / 255.0, green: 0x96 / 255.0, blue: 0x88 / 255.0) // Material Teal 500
        public static let teal700 = Color(red: 0x00 / 255.0, green: 0x79 / 255.0, blue: 0x6B / 255.0) // Deep Teal (Light primary)
        public static let teal300 = Color(red: 0x4D / 255.0, green: 0xB6 / 255.0, blue: 0xAC / 255.0) // Vibrant Mint Teal (Dark primary)
        public static let tealLogo = Color(red: 0x00 / 255.0, green: 0x80 / 255.0, blue: 0x80 / 255.0) // Exact Logo PLTE Teal
        public static let tealSoftContainer = Color(red: 0xE0 / 255.0, green: 0xF2 / 255.0, blue: 0xF1 / 255.0) // Teal.shade100
        public static let tealDarkContainer = Color(red: 0x00 / 255.0, green: 0x4D / 255.0, blue: 0x40 / 255.0)
    }

    // MARK: - Dynamic Semantic Colors
    public static func accent(for preference: AccentColorPreference = .localSend, colorScheme: ColorScheme = .light) -> Color {
        switch preference {
        case .localSend:
            return colorScheme == .dark ? Brand.teal300 : Brand.teal700
        case .system:
            #if os(macOS)
            return Color(nsColor: .controlAccentColor)
            #else
            return Color.accentColor
            #endif
        }
    }

    public static func accentGradient(for preference: AccentColorPreference = .localSend, colorScheme: ColorScheme = .light) -> LinearGradient {
        let base = accent(for: preference, colorScheme: colorScheme)
        let secondary = preference == .localSend
            ? (colorScheme == .dark ? Color(red: 0x26 / 255.0, green: 0xA6 / 255.0, blue: 0x9A / 255.0) : Brand.teal500)
            : base.opacity(0.85)

        return LinearGradient(
            colors: [base, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static func accentContainer(for preference: AccentColorPreference = .localSend, colorScheme: ColorScheme = .light) -> Color {
        switch preference {
        case .localSend:
            return colorScheme == .dark
                ? Brand.tealDarkContainer.opacity(0.45)
                : Brand.tealSoftContainer.opacity(0.65)
        case .system:
            return accent(for: .system, colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.22 : 0.12)
        }
    }

    // Semantic States
    public static let success = Color(red: 0x34 / 255.0, green: 0xC7 / 255.0, blue: 0x59 / 255.0) // Apple Green
    public static let warning = Color(red: 0xFF / 255.0, green: 0x95 / 255.0, blue: 0x00 / 255.0) // Apple Orange
    public static let error = Color(red: 0xFF / 255.0, green: 0x3B / 255.0, blue: 0x30 / 255.0)   // Apple Red
    public static let info = Color(red: 0x00 / 255.0, green: 0x7A / 255.0, blue: 0xFF / 255.0)    // Apple Blue

    // Backgrounds
    #if os(macOS)
    public static let primaryBackground = Color(nsColor: .windowBackgroundColor)
    public static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
    public static let tertiaryBackground = Color(nsColor: .underPageBackgroundColor)
    public static let cardBackground = Color(nsColor: .controlBackgroundColor).opacity(0.7)
    public static let elevatedCardBackground = Color(nsColor: .windowBackgroundColor)
    public static let borderSubtle = Color(nsColor: .separatorColor).opacity(0.6)
    #else
    public static let primaryBackground = Color(uiColor: .systemBackground)
    public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    public static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    public static let elevatedCardBackground = Color(uiColor: .systemBackground)
    public static let borderSubtle = Color(uiColor: .separator).opacity(0.6)
    #endif

    // File Type Colors
    public static func fileTypeColor(for ext: String) -> Color {
        switch ext.lowercased() {
        case "jpg", "jpeg", "png", "heic", "gif", "webp", "svg", "raw", "tiff":
            return Color(red: 0xAF / 255.0, green: 0x52 / 255.0, blue: 0xDE / 255.0) // Purple/Pink
        case "mp4", "mov", "m4v", "mkv", "avi", "webm":
            return Color(red: 0x58 / 255.0, green: 0x56 / 255.0, blue: 0xD6 / 255.0) // Indigo
        case "mp3", "m4a", "wav", "flac", "aac", "ogg":
            return Color(red: 0xFF / 255.0, green: 0x95 / 255.0, blue: 0x00 / 255.0) // Orange
        case "pdf", "doc", "docx", "pages", "xls", "xlsx", "ppt", "pptx":
            return Color(red: 0x00 / 255.0, green: 0x7A / 255.0, blue: 0xFF / 255.0) // Blue
        case "zip", "tar", "gz", "rar", "7z", "dmg", "pkg":
            return Color(red: 0x8E / 255.0, green: 0x8E / 255.0, blue: 0x93 / 255.0) // Slate Gray
        case "swift", "rs", "py", "js", "ts", "json", "html", "css", "md", "txt":
            return Brand.teal500 // LocalSend Teal
        default:
            return Color.secondary
        }
    }
}

public struct ShadowToken: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

public extension View {
    func localSendShadow(_ token: ShadowToken) -> some View {
        self.shadow(color: token.color, radius: token.radius, x: token.x, y: token.y)
    }

    func localSendCardStyle(
        cornerRadius: CGFloat = LocalSendTheme.cornerRadiusCard,
        strokeColor: Color = LocalSendTheme.borderSubtle
    ) -> some View {
        self
            .padding(LocalSendTheme.spacingMedium)
            .background(LocalSendTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
    }

    func localSendInteractiveCardStyle(
        isHovered: Bool = false,
        isSelected: Bool = false,
        accentColor: Color = LocalSendTheme.accent()
    ) -> some View {
        self
            .padding(LocalSendTheme.spacingMedium)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.12) : (isHovered ? LocalSendTheme.cardBackground.opacity(0.9) : LocalSendTheme.cardBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusCard, style: .continuous)
                    .stroke(
                        isSelected ? accentColor : (isHovered ? accentColor.opacity(0.4) : LocalSendTheme.borderSubtle),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isHovered ? 1.015 : 1.0)
            .localSendShadow(isHovered ? LocalSendTheme.shadowMedium : LocalSendTheme.shadowSubtle)
    }
}
