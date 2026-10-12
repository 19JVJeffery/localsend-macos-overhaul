import 'package:flutter/material.dart';

/// Standard Apple macOS typography adhering to Apple Human Interface Guidelines.
class MacosTypography {
  static const String? _systemFont = null; // System font (SF Pro)

  static TextStyle largeTitle({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.35,
    color: color,
  );

  static TextStyle title1({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 21,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
    color: color,
  );

  static TextStyle title2({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: color,
  );

  static TextStyle title3({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: color,
  );

  static TextStyle headline({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.05,
    color: color,
  );

  static TextStyle body({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.05,
    color: color,
  );

  static TextStyle bodyMedium({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.05,
    color: color,
  );

  static TextStyle callout({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.05,
    color: color,
  );

  static TextStyle subheadline({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    color: color,
  );

  static TextStyle subheadlineMedium({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: color,
  );

  static TextStyle footnote({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.05,
    color: color,
  );

  static TextStyle caption({required Color color}) => TextStyle(
    fontFamily: _systemFont,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.1,
    color: color,
  );

  static TextStyle tabularFigures({
    required TextStyle style,
  }) => style.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
