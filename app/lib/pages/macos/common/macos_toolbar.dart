import 'package:flutter/cupertino.dart';
import 'package:localsend_app/pages/macos/common/macos_button.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';

class MacosToolbar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onToggleSidebar;
  final List<Widget>? actions;

  const MacosToolbar({
    super.key,
    required this.title,
    this.subtitle,
    required this.onToggleSidebar,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: macTheme.windowBackground,
        border: Border(
          bottom: BorderSide(
            color: macTheme.border,
            width: 0.75,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          MacosIconButton(
            icon: const Icon(CupertinoIcons.sidebar_left),
            tooltip: 'Toggle Sidebar',
            onPressed: onToggleSidebar,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: MacosTypography.headline(color: macTheme.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: MacosTypography.caption(color: macTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
