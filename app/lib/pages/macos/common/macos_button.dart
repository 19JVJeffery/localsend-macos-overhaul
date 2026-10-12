import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';

enum MacosButtonVariant {
  primary,
  secondary,
  destructive,
  plain,
}

enum MacosButtonSize {
  small(height: 24, horizontalPadding: 8, fontSize: 11, iconSize: 12),
  medium(height: 28, horizontalPadding: 12, fontSize: 13, iconSize: 14),
  large(height: 34, horizontalPadding: 16, fontSize: 14, iconSize: 16)
  ;

  final double height;
  final double horizontalPadding;
  final double fontSize;
  final double iconSize;

  const MacosButtonSize({
    required this.height,
    required this.horizontalPadding,
    required this.fontSize,
    required this.iconSize,
  });
}

class MacosButton extends StatefulWidget {
  final Widget? icon;
  final String text;
  final VoidCallback? onPressed;
  final MacosButtonVariant variant;
  final MacosButtonSize size;
  final bool isLoading;
  final String? tooltip;

  const MacosButton({
    super.key,
    this.icon,
    required this.text,
    this.onPressed,
    this.variant = MacosButtonVariant.secondary,
    this.size = MacosButtonSize.medium,
    this.isLoading = false,
    this.tooltip,
  });

  @override
  State<MacosButton> createState() => _MacosButtonState();
}

class _MacosButtonState extends State<MacosButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (widget.variant) {
      case MacosButtonVariant.primary:
        backgroundColor = isEnabled ? macTheme.accent : macTheme.accent.withValues(alpha: 0.4);
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
        if (_isPressed && isEnabled) {
          backgroundColor = Color.alphaBlend(Colors.black.withValues(alpha: 0.15), backgroundColor);
        } else if (_isHovered && isEnabled) {
          backgroundColor = Color.alphaBlend(Colors.white.withValues(alpha: 0.1), backgroundColor);
        }
        break;

      case MacosButtonVariant.secondary:
        backgroundColor = macTheme.isDark ? const Color(0xFF323236) : const Color(0xFFFFFFFF);
        foregroundColor = isEnabled ? macTheme.textPrimary : macTheme.textTertiary;
        borderColor = macTheme.border;
        if (_isPressed && isEnabled) {
          backgroundColor = macTheme.isDark ? const Color(0xFF3E3E44) : const Color(0xFFECECEE);
        } else if (_isHovered && isEnabled) {
          backgroundColor = macTheme.isDark ? const Color(0xFF38383D) : const Color(0xFFF7F7F9);
        }
        break;

      case MacosButtonVariant.destructive:
        backgroundColor = isEnabled ? macTheme.error : macTheme.error.withValues(alpha: 0.4);
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
        if (_isPressed && isEnabled) {
          backgroundColor = Color.alphaBlend(Colors.black.withValues(alpha: 0.2), backgroundColor);
        } else if (_isHovered && isEnabled) {
          backgroundColor = Color.alphaBlend(Colors.white.withValues(alpha: 0.1), backgroundColor);
        }
        break;

      case MacosButtonVariant.plain:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? macTheme.textPrimary : macTheme.textTertiary;
        borderColor = Colors.transparent;
        if (_isPressed && isEnabled) {
          backgroundColor = macTheme.hoverBackground.withValues(alpha: 0.2);
        } else if (_isHovered && isEnabled) {
          backgroundColor = macTheme.hoverBackground;
        }
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: widget.size.iconSize,
            height: widget.size.iconSize,
            child: CupertinoActivityIndicator(
              radius: widget.size.iconSize / 2,
              color: foregroundColor,
            ),
          ),
          const SizedBox(width: 6),
        ] else if (widget.icon != null) ...[
          IconTheme(
            data: IconThemeData(
              size: widget.size.iconSize,
              color: foregroundColor,
            ),
            child: widget.icon!,
          ),
          const SizedBox(width: 6),
        ],
        Text(
          widget.text,
          style: MacosTypography.body(color: foregroundColor).copyWith(
            fontSize: widget.size.fontSize,
            fontWeight: widget.variant == MacosButtonVariant.primary ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );

    Widget button = MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.size.height,
          padding: EdgeInsets.symmetric(horizontal: widget.size.horizontalPadding),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: borderColor,
              width: 0.75,
            ),
            boxShadow: widget.variant == MacosButtonVariant.secondary && !_isPressed && isEnabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: macTheme.isDark ? 0.2 : 0.04),
                      blurRadius: 1,
                      offset: const Offset(0, 0.75),
                    ),
                  ]
                : null,
          ),
          child: content,
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 600),
        child: button,
      );
    }

    return button;
  }
}

class MacosIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;
  final bool isSelected;

  const MacosIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 28,
    this.color,
    this.isSelected = false,
  });

  @override
  State<MacosIconButton> createState() => _MacosIconButtonState();
}

class _MacosIconButtonState extends State<MacosIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);
    final isEnabled = widget.onPressed != null;

    final backgroundColor = widget.isSelected
        ? macTheme.activeSelection
        : _isPressed
        ? macTheme.hoverBackground.withValues(alpha: 0.25)
        : _isHovered
        ? macTheme.hoverBackground
        : Colors.transparent;

    final iconColor = widget.color ?? (isEnabled ? macTheme.textPrimary : macTheme.textTertiary);

    Widget button = MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                size: widget.size * 0.58,
                color: iconColor,
              ),
              child: widget.icon,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: button,
      );
    }

    return button;
  }
}
