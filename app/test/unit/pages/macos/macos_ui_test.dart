import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/macos/macos_home_page.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';

void main() {
  group('macOS Theme & Typography', () {
    test('Light theme semantic colors match Apple HIG specifications', () {
      const theme = MacosThemeData(
        brightness: Brightness.light,
        accent: Color(0xFF007AFF),
      );

      expect(theme.isDark, isFalse);
      expect(theme.windowBackground, const Color(0xFFF5F5F7));
      expect(theme.sidebarBackground, const Color(0xFFEBEBF0));
      expect(theme.contentBackground, const Color(0xFFFFFFFF));
      expect(theme.cardBackground, const Color(0xFFFFFFFF));
      expect(theme.textPrimary, const Color(0xFF1D1D1F));
      expect(theme.textSecondary, const Color(0xFF6E6E73));
      expect(theme.cardShadow, isNotEmpty);
      expect(theme.popoverShadow, isNotEmpty);
    });

    test('Dark theme semantic colors match Apple HIG specifications', () {
      const theme = MacosThemeData(
        brightness: Brightness.dark,
        accent: Color(0xFF0A84FF),
      );

      expect(theme.isDark, isTrue);
      expect(theme.windowBackground, const Color(0xFF1E1E20));
      expect(theme.sidebarBackground, const Color(0xFF242426));
      expect(theme.contentBackground, const Color(0xFF1B1B1D));
      expect(theme.cardBackground, const Color(0xFF28282B));
      expect(theme.textPrimary, const Color(0xFFFFFFFF));
      expect(theme.textSecondary, const Color(0xFFA1A1A6));
      expect(theme.cardShadow, isNotEmpty);
      expect(theme.popoverShadow, isNotEmpty);
    });

    test('Typography provides expected sizing and tabular figures', () {
      final title = MacosTypography.largeTitle(color: Colors.black);
      expect(title.fontSize, 26);
      expect(title.fontWeight, FontWeight.bold);

      final headline = MacosTypography.headline(color: Colors.black);
      expect(headline.fontSize, 13);
      expect(headline.fontWeight, FontWeight.w600);

      final tabularHeadline = MacosTypography.tabularFigures(style: headline);
      expect(tabularHeadline.fontFeatures, isNotNull);
      expect(tabularHeadline.fontFeatures!.any((f) => f.feature == 'tnum'), isTrue);
    });
  });

  group('macOS Navigation Tabs', () {
    test('MacosNavigationTab contains all 4 desktop sections', () {
      expect(MacosNavigationTab.values.length, 4);
      expect(MacosNavigationTab.values, contains(MacosNavigationTab.send));
      expect(MacosNavigationTab.values, contains(MacosNavigationTab.receive));
      expect(MacosNavigationTab.values, contains(MacosNavigationTab.transfers));
      expect(MacosNavigationTab.values, contains(MacosNavigationTab.settings));
    });

    test('Maps HomeTab accurately', () {
      expect(MacosHomePage(initialTab: HomeTab.send).initialTab, HomeTab.send);
      expect(MacosHomePage(initialTab: HomeTab.receive).initialTab, HomeTab.receive);
      expect(MacosHomePage(initialTab: HomeTab.settings).initialTab, HomeTab.settings);
    });
  });
}
