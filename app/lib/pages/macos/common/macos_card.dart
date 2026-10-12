import 'package:flutter/material.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';

class MacosCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  const MacosCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 10,
    this.onTap,
    this.isSelected = false,
    this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);

    Widget content = child;

    if (title != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      style: MacosTypography.headline(color: macTheme.textPrimary),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: MacosTypography.subheadline(color: macTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      );
    }

    final effectiveBg = backgroundColor ?? (macTheme.isDark ? const Color(0xFF262629) : const Color(0xFFFFFFFF));
    final effectiveBorder = isSelected ? macTheme.accent : (borderColor ?? (macTheme.isDark ? const Color(0xFF38383D) : const Color(0xFFE5E5EA)));

    Widget card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorder,
          width: isSelected ? 1.5 : 0.8,
        ),
        boxShadow: macTheme.cardShadow,
      ),
      child: content,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    return card;
  }
}
