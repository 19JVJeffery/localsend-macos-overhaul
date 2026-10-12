import 'package:flutter/material.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';

class MacosBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final Widget? icon;
  final bool isPill;

  const MacosBadge({
    super.key,
    required this.text,
    this.color,
    this.textColor,
    this.icon,
    this.isPill = true,
  });

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);
    final bg = color ?? macTheme.controlBackground;
    final fg = textColor ?? macTheme.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPill ? 8 : 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isPill ? 12 : 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(size: 11, color: fg),
              child: icon!,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: MacosTypography.caption(color: fg).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class MacosStatusDot extends StatelessWidget {
  final bool isOnline;
  final double size;

  const MacosStatusDot({
    super.key,
    required this.isOnline,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);
    final color = isOnline ? macTheme.success : macTheme.textTertiary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
