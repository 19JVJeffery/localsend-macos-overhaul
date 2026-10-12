import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/about/about_page.dart';
import 'package:localsend_app/pages/macos/macos_home_page.dart';
import 'package:localsend_app/pages/troubleshoot_page.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/native/directories.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/util/native/open_folder.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class MacosMenuBarScope extends StatelessWidget {
  final Widget child;
  final Function(MacosNavigationTab tab) onSelectTab;
  final VoidCallback onToggleSidebar;

  const MacosMenuBarScope({
    super.key,
    required this.child,
    required this.onSelectTab,
    required this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'LocalSend',
          menus: [
            PlatformMenuItem(
              label: t.aboutPage.title,
              onSelected: () async {
                await context.push(() => const AboutPage());
              },
            ),
            const PlatformMenuItemGroup(
              members: [
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.servicesSubmenu,
                ),
              ],
            ),
            PlatformMenuItem(
              label: t.settingsTab.title,
              shortcut: const SingleActivator(LogicalKeyboardKey.comma, meta: true),
              onSelected: () => onSelectTab(MacosNavigationTab.settings),
            ),
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.hide,
            ),
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.hideOtherApplications,
            ),
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.showAllApplications,
            ),
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.quit,
            ),
          ],
        ),
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItem(
              label: '${t.sendTab.picker.file}...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
              onSelected: () async {
                onSelectTab(MacosNavigationTab.send);
                await context.global.dispatchAsync(
                  PickFileAction(
                    option: FilePickerOption.file,
                    context: context,
                  ),
                );
              },
            ),
            PlatformMenuItem(
              label: '${t.sendTab.picker.folder}...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true, shift: true),
              onSelected: () async {
                onSelectTab(MacosNavigationTab.send);
                await context.global.dispatchAsync(
                  PickFileAction(
                    option: FilePickerOption.folder,
                    context: context,
                  ),
                );
              },
            ),
            PlatformMenuItem(
              label: '${t.sendTab.picker.text}...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyT, meta: true),
              onSelected: () async {
                onSelectTab(MacosNavigationTab.send);
                await context.global.dispatchAsync(
                  PickFileAction(
                    option: FilePickerOption.text,
                    context: context,
                  ),
                );
              },
            ),
            PlatformMenuItem(
              label: t.sendTab.picker.clipboard,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyV, meta: true, shift: true),
              onSelected: () async {
                onSelectTab(MacosNavigationTab.send);
                await context.global.dispatchAsync(
                  PickFileAction(
                    option: FilePickerOption.clipboard,
                    context: context,
                  ),
                );
              },
            ),
            PlatformMenuItem(
              label: t.receiveHistoryPage.openFolder,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyD, meta: true, shift: true),
              onSelected: () async {
                final customDest = context.read(settingsProvider).destination;
                final destination = customDest ?? await getDefaultDestinationDirectory();
                await openFolder(folderPath: destination);
              },
            ),
          ],
        ),
        PlatformMenu(
          label: 'View',
          menus: [
            PlatformMenuItem(
              label: t.sendTab.title,
              shortcut: const SingleActivator(LogicalKeyboardKey.digit1, meta: true),
              onSelected: () => onSelectTab(MacosNavigationTab.send),
            ),
            PlatformMenuItem(
              label: t.receiveTab.title,
              shortcut: const SingleActivator(LogicalKeyboardKey.digit2, meta: true),
              onSelected: () => onSelectTab(MacosNavigationTab.receive),
            ),
            PlatformMenuItem(
              label: t.receiveHistoryPage.title,
              shortcut: const SingleActivator(LogicalKeyboardKey.digit3, meta: true),
              onSelected: () => onSelectTab(MacosNavigationTab.transfers),
            ),
            PlatformMenuItem(
              label: t.settingsTab.title,
              shortcut: const SingleActivator(LogicalKeyboardKey.digit4, meta: true),
              onSelected: () => onSelectTab(MacosNavigationTab.settings),
            ),
            PlatformMenuItem(
              label: 'Toggle Sidebar',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true, control: true),
              onSelected: onToggleSidebar,
            ),
            PlatformMenuItem(
              label: 'Scan for Devices',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyR, meta: true),
              onSelected: () async {
                await context.global.dispatchAsync(StartSmartScan());
              },
            ),
          ],
        ),
        PlatformMenu(
          label: 'Window',
          menus: const [
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.minimizeWindow,
            ),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.zoomWindow,
            ),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.arrangeWindowsInFront,
            ),
          ],
        ),
        PlatformMenu(
          label: 'Help',
          menus: [
            PlatformMenuItem(
              label: t.troubleshootPage.title,
              shortcut: const SingleActivator(LogicalKeyboardKey.slash, meta: true, shift: true),
              onSelected: () async {
                await context.push(() => const TroubleshootPage());
              },
            ),
          ],
        ),
      ],
      child: child,
    );
  }
}
