import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/macos/common/macos_badge.dart';
import 'package:localsend_app/pages/macos/macos_home_page.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/receive_history_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/ip_helper.dart';
import 'package:localsend_app/widget/local_send_logo.dart';
import 'package:refena_flutter/refena_flutter.dart';

class MacosSidebar extends StatelessWidget {
  final MacosNavigationTab currentTab;
  final ValueChanged<MacosNavigationTab> onSelectTab;
  final bool isCollapsed;

  const MacosSidebar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);
    final historyCount = context.watch(receiveHistoryProvider.select((list) => list.length));
    final serverState = context.watch(serverProvider);
    final isOnline = serverState != null;
    final alias = context.watch(settingsProvider.select((s) => s.alias));
    final localIps = context.watch(localIpProvider.select((s) => s.localIps));
    final visualId = localIps.isNotEmpty ? '#${localIps.first.visualId}' : null;

    if (isCollapsed) {
      return Container(
        width: 68,
        decoration: BoxDecoration(
          color: macTheme.sidebarBackground,
          border: Border(
            right: BorderSide(color: macTheme.border, width: 0.75),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 52), // Traffic light inset
            const LocalSendLogo(withText: false),
            const SizedBox(height: 24),
            _CollapsedNavItem(
              icon: CupertinoIcons.paperplane_fill,
              isSelected: currentTab == MacosNavigationTab.send,
              onTap: () => onSelectTab(MacosNavigationTab.send),
              tooltip: t.sendTab.title,
            ),
            const SizedBox(height: 8),
            _CollapsedNavItem(
              icon: CupertinoIcons.arrow_down_circle_fill,
              isSelected: currentTab == MacosNavigationTab.receive,
              onTap: () => onSelectTab(MacosNavigationTab.receive),
              tooltip: t.receiveTab.title,
            ),
            const SizedBox(height: 8),
            _CollapsedNavItem(
              icon: CupertinoIcons.clock_fill,
              isSelected: currentTab == MacosNavigationTab.transfers,
              onTap: () => onSelectTab(MacosNavigationTab.transfers),
              badgeCount: historyCount > 0 ? historyCount : null,
              tooltip: t.receiveHistoryPage.title,
            ),
            const Spacer(),
            _CollapsedNavItem(
              icon: CupertinoIcons.gear_alt_fill,
              isSelected: currentTab == MacosNavigationTab.settings,
              onTap: () => onSelectTab(MacosNavigationTab.settings),
              tooltip: t.settingsTab.title,
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: macTheme.sidebarBackground,
        border: Border(
          right: BorderSide(color: macTheme.border, width: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48), // Traffic light inset
          // App Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: LocalSendLogo(withText: false),
                ),
                const SizedBox(width: 10),
                Text(
                  'LocalSend',
                  style: MacosTypography.title3(color: macTheme.textPrimary).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                MacosStatusDot(isOnline: isOnline),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Navigation List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _SidebarNavItem(
                  icon: CupertinoIcons.paperplane_fill,
                  label: t.sendTab.title,
                  isSelected: currentTab == MacosNavigationTab.send,
                  onTap: () => onSelectTab(MacosNavigationTab.send),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: CupertinoIcons.arrow_down_circle_fill,
                  label: t.receiveTab.title,
                  isSelected: currentTab == MacosNavigationTab.receive,
                  onTap: () => onSelectTab(MacosNavigationTab.receive),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: CupertinoIcons.clock_fill,
                  label: t.receiveHistoryPage.title,
                  isSelected: currentTab == MacosNavigationTab.transfers,
                  badgeCount: historyCount > 0 ? historyCount : null,
                  onTap: () => onSelectTab(MacosNavigationTab.transfers),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: CupertinoIcons.gear_alt_fill,
                  label: t.settingsTab.title,
                  isSelected: currentTab == MacosNavigationTab.settings,
                  onTap: () => onSelectTab(MacosNavigationTab.settings),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Bottom Device Status Badge
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: macTheme.isDark ? const Color(0xFF2C2C2F) : const Color(0xFFE2E2E7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: macTheme.subtleBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  MacosStatusDot(isOnline: isOnline, size: 7),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          serverState?.alias ?? alias,
                          style: MacosTypography.subheadline(color: macTheme.textPrimary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (visualId != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            visualId,
                            style: MacosTypography.caption(color: macTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badgeCount,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);

    final bg = widget.isSelected
        ? macTheme.accent
        : _isHovered
        ? macTheme.hoverBackground
        : Colors.transparent;

    final fg = widget.isSelected ? Colors.white : macTheme.textPrimary;

    final iconColor = widget.isSelected ? Colors.white : macTheme.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: MacosTypography.body(color: fg).copyWith(
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.badgeCount != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isSelected ? Colors.white.withValues(alpha: 0.25) : macTheme.controlBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.badgeCount! > 99 ? '99+' : '${widget.badgeCount}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.isSelected ? Colors.white : macTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsedNavItem extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;
  final String tooltip;

  const _CollapsedNavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
    required this.tooltip,
  });

  @override
  State<_CollapsedNavItem> createState() => _CollapsedNavItemState();
}

class _CollapsedNavItemState extends State<_CollapsedNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);

    final bg = widget.isSelected
        ? macTheme.accent
        : _isHovered
        ? macTheme.hoverBackground
        : Colors.transparent;

    final iconColor = widget.isSelected ? Colors.white : macTheme.textPrimary;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: iconColor,
                ),
                if (widget.badgeCount != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.isSelected ? Colors.white : macTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
