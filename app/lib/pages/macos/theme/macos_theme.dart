import 'package:flutter/material.dart';

/// Semantic colors and styling adhering to Apple macOS Human Interface Guidelines.
class MacosThemeData {
  final Brightness brightness;
  final Color accent;

  const MacosThemeData({
    required this.brightness,
    required this.accent,
  });

  bool get isDark => brightness == Brightness.dark;

  // Background surfaces
  Color get windowBackground => isDark ? const Color(0xFF1E1E20) : const Color(0xFFF5F5F7);
  Color get sidebarBackground => isDark ? const Color(0xFF242426) : const Color(0xFFEBEBF0);
  Color get contentBackground => isDark ? const Color(0xFF1B1B1D) : const Color(0xFFFFFFFF);
  Color get cardBackground => isDark ? const Color(0xFF28282B) : const Color(0xFFFFFFFF);
  Color get controlBackground => isDark ? const Color(0xFF323236) : const Color(0xFFE5E5EA);
  Color get searchBackground => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE3E3E8);

  // Borders and dividers
  Color get border => isDark ? const Color(0xFF38383C) : const Color(0xFFDCDCE0);
  Color get divider => isDark ? const Color(0xFF323236) : const Color(0xFFE5E5EA);
  Color get subtleBorder => isDark ? const Color(0xFF2E2E32) : const Color(0xFFEDEDF2);

  // States
  Color get hoverBackground => isDark ? const Color(0x14FFFFFF) : const Color(0x0A000000);
  Color get pressedBackground => isDark ? const Color(0x24FFFFFF) : const Color(0x14000000);
  Color get activeSelection => accent.withValues(alpha: isDark ? 0.28 : 0.16);
  Color get selectedBorder => accent.withValues(alpha: 0.5);

  // Typography colors
  Color get textPrimary => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1D1D1F);
  Color get textSecondary => isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73);
  Color get textTertiary => isDark ? const Color(0xFF6E6E73) : const Color(0xFF8E8E93);
  Color get textQuaternary => isDark ? const Color(0xFF48484A) : const Color(0xFFAEAEB2);

  // Semantic status colors (Apple HIG)
  Color get success => isDark ? const Color(0xFF34C759) : const Color(0xFF248A3D);
  Color get successContainer => isDark ? const Color(0xFF0F3818) : const Color(0xFFEAF8EC);
  Color get error => isDark ? const Color(0xFFFF453A) : const Color(0xFFD70015);
  Color get errorContainer => isDark ? const Color(0xFF3D1412) : const Color(0xFFFDEEEC);
  Color get warning => isDark ? const Color(0xFFFF9F0A) : const Color(0xFFC97800);
  Color get warningContainer => isDark ? const Color(0xFF3D2B0F) : const Color(0xFFFFF6E5);

  // Shadows
  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ];

  List<BoxShadow> get popoverShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ];
}

class MacosTheme extends InheritedWidget {
  final MacosThemeData data;

  const MacosTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static MacosThemeData of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<MacosTheme>();
    if (widget != null) {
      return widget.data;
    }
    final theme = Theme.of(context);
    return MacosThemeData(
      brightness: theme.brightness,
      accent: theme.colorScheme.primary,
    );
  }

  @override
  bool updateShouldNotify(covariant MacosTheme oldWidget) {
    return oldWidget.data.brightness != data.brightness || oldWidget.data.accent != data.accent;
  }
}
