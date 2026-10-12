import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/about/about_page.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/macos/common/macos_button.dart';
import 'package:localsend_app/pages/macos/common/macos_menu_bar.dart';
import 'package:localsend_app/pages/macos/common/macos_sidebar.dart';
import 'package:localsend_app/pages/macos/common/macos_toolbar.dart';
import 'package:localsend_app/pages/macos/tabs/macos_activity_tab.dart';
import 'package:localsend_app/pages/macos/tabs/macos_receive_tab.dart';
import 'package:localsend_app/pages/macos/tabs/macos_send_tab.dart';
import 'package:localsend_app/pages/macos/tabs/macos_settings_tab.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';
import 'package:localsend_app/pages/troubleshoot_page.dart';
import 'package:localsend_app/pages/web_share_page.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/util/native/directories.dart';
import 'package:localsend_app/util/native/open_folder.dart';
import 'package:localsend_app/widget/dialogs/history_clear_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

enum MacosNavigationTab {
  send,
  receive,
  transfers,
  settings
  ;

  String get label {
    switch (this) {
      case MacosNavigationTab.send:
        return t.sendTab.title;
      case MacosNavigationTab.receive:
        return t.receiveTab.title;
      case MacosNavigationTab.transfers:
        return t.receiveHistoryPage.title;
      case MacosNavigationTab.settings:
        return t.settingsTab.title;
    }
  }
}

class MacosHomePage extends StatefulWidget {
  final HomeTab initialTab;
  final bool appStart;

  const MacosHomePage({
    this.initialTab = HomeTab.receive,
    this.appStart = false,
    super.key,
  });

  @override
  State<MacosHomePage> createState() => _MacosHomePageState();
}

class _MacosHomePageState extends State<MacosHomePage> with Refena {
  late MacosNavigationTab _currentTab;
  late final PageController _pageController;
  bool _isSidebarCollapsed = false;
  bool _isDraggingOver = false;

  @override
  void initState() {
    super.initState();
    _currentTab = _mapHomeTabToMacosTab(widget.initialTab);
    _pageController = PageController(initialPage: _currentTab.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static MacosNavigationTab _mapHomeTabToMacosTab(HomeTab tab) {
    switch (tab) {
      case HomeTab.send:
        return MacosNavigationTab.send;
      case HomeTab.receive:
        return MacosNavigationTab.receive;
      case HomeTab.settings:
        return MacosNavigationTab.settings;
    }
  }

  static HomeTab? _mapMacosTabToHomeTab(MacosNavigationTab tab) {
    switch (tab) {
      case MacosNavigationTab.send:
        return HomeTab.send;
      case MacosNavigationTab.receive:
        return HomeTab.receive;
      case MacosNavigationTab.settings:
        return HomeTab.settings;
      case MacosNavigationTab.transfers:
        return null;
    }
  }

  void _selectTab(MacosNavigationTab tab) {
    if (_currentTab == tab) return;

    setState(() {
      _currentTab = tab;
    });

    _pageController.jumpToPage(tab.index);

    final homeTab = _mapMacosTabToHomeTab(tab);
    if (homeTab != null) {
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(homeTab));
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  String _getToolbarTitle() {
    switch (_currentTab) {
      case MacosNavigationTab.send:
        return t.sendTab.title;
      case MacosNavigationTab.receive:
        return t.receiveTab.title;
      case MacosNavigationTab.transfers:
        return t.receiveHistoryPage.title;
      case MacosNavigationTab.settings:
        return t.settingsTab.title;
    }
  }

  String? _getToolbarSubtitle(BuildContext context) {
    switch (_currentTab) {
      case MacosNavigationTab.send:
        return 'Send files and messages to nearby devices';
      case MacosNavigationTab.receive:
        final alias = context.watch(settingsProvider.select((s) => s.alias));
        final serverRunning = context.watch(serverProvider) != null;
        final localIps = context.watch(localIpProvider.select((s) => s.localIps));
        final ipText = localIps.isNotEmpty ? localIps.first : '';
        return serverRunning ? '$alias • $ipText' : '$alias • Offline';
      case MacosNavigationTab.transfers:
        return 'Recent incoming and outgoing file transfers';
      case MacosNavigationTab.settings:
        return 'Preferences and network configuration';
    }
  }

  List<Widget>? _buildToolbarActions(BuildContext context) {
    switch (_currentTab) {
      case MacosNavigationTab.send:
        return [
          MacosIconButton(
            icon: const Icon(CupertinoIcons.arrow_clockwise),
            tooltip: 'Refresh Nearby Devices',
            onPressed: () async {
              await context.global.dispatchAsync(StartSmartScan());
            },
          ),
          const SizedBox(width: 6),
          MacosIconButton(
            icon: const Icon(CupertinoIcons.question_circle),
            tooltip: t.troubleshootPage.title,
            onPressed: () async {
              await context.push(() => const TroubleshootPage());
            },
          ),
        ];
      case MacosNavigationTab.receive:
        return [
          MacosIconButton(
            icon: const Icon(CupertinoIcons.folder),
            tooltip: t.receiveHistoryPage.openFolder,
            onPressed: () async {
              final destination = ref.read(settingsProvider).destination ?? await getDefaultDestinationDirectory();
              await openFolder(folderPath: destination);
            },
          ),
          const SizedBox(width: 6),
          MacosIconButton(
            icon: const Icon(CupertinoIcons.globe),
            tooltip: t.webSharePage.title,
            onPressed: () async {
              await context.push(() => const WebSharePage());
            },
          ),
        ];
      case MacosNavigationTab.transfers:
        return [
          MacosIconButton(
            icon: const Icon(CupertinoIcons.folder),
            tooltip: t.receiveHistoryPage.openFolder,
            onPressed: () async {
              final destination = ref.read(settingsProvider).destination ?? await getDefaultDestinationDirectory();
              await openFolder(folderPath: destination);
            },
          ),
          const SizedBox(width: 6),
          MacosIconButton(
            icon: const Icon(CupertinoIcons.trash),
            tooltip: t.receiveHistoryPage.deleteHistory,
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => const HistoryClearDialog(),
              );
            },
          ),
        ];
      case MacosNavigationTab.settings:
        return [
          MacosIconButton(
            icon: const Icon(CupertinoIcons.info_circle),
            tooltip: t.aboutPage.title,
            onPressed: () async {
              await context.push(() => const AboutPage());
            },
          ),
          const SizedBox(width: 6),
          MacosIconButton(
            icon: const Icon(CupertinoIcons.question_circle),
            tooltip: t.troubleshootPage.title,
            onPressed: () async {
              await context.push(() => const TroubleshootPage());
            },
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    Translations.of(context);
    final theme = Theme.of(context);
    final macTheme = MacosTheme.of(context);

    // Synchronize with external changes to homePageControllerProvider
    final homePageVm = context.watch(homePageControllerProvider);
    final expectedMacosTab = _mapHomeTabToMacosTab(homePageVm.currentTab);
    if (_currentTab != MacosNavigationTab.transfers && _currentTab != expectedMacosTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentTab != expectedMacosTab) {
          setState(() {
            _currentTab = expectedMacosTab;
          });
          _pageController.jumpToPage(expectedMacosTab.index);
        }
      });
    }

    return MacosMenuBarScope(
      onSelectTab: _selectTab,
      onToggleSidebar: _toggleSidebar,
      child: MacosTheme(
        data: MacosThemeData(
          brightness: theme.brightness,
          accent: theme.colorScheme.primary,
        ),
        child: Scaffold(
          backgroundColor: macTheme.windowBackground,
          body: DropTarget(
            onDragEntered: (_) {
              setState(() {
                _isDraggingOver = true;
              });
            },
            onDragExited: (_) {
              setState(() {
                _isDraggingOver = false;
              });
            },
            onDragDone: (event) async {
              setState(() {
                _isDraggingOver = false;
              });

              final droppedDirectories = event.files.where((file) => Directory(file.path).existsSync()).toList();
              final droppedFiles = event.files.where((file) => !Directory(file.path).existsSync()).toList();

              for (final directory in droppedDirectories) {
                await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(directory.path));
              }

              if (droppedFiles.isNotEmpty) {
                await ref
                    .redux(selectedSendingFilesProvider)
                    .dispatchAsync(
                      AddFilesAction(
                        files: droppedFiles,
                        converter: CrossFileConverters.convertXFile,
                      ),
                    );
              }

              _selectTab(MacosNavigationTab.send);
            },
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MacosSidebar(
                      currentTab: _currentTab,
                      onSelectTab: _selectTab,
                      isCollapsed: _isSidebarCollapsed,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MacosToolbar(
                            title: _getToolbarTitle(),
                            subtitle: _getToolbarSubtitle(context),
                            onToggleSidebar: _toggleSidebar,
                            actions: _buildToolbarActions(context),
                          ),
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: const [
                                MacosSendTab(),
                                MacosReceiveTab(),
                                MacosActivityTab(),
                                MacosSettingsTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isDraggingOver)
                  Positioned.fill(
                    child: Container(
                      color: macTheme.windowBackground.withValues(alpha: 0.90),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                        decoration: BoxDecoration(
                          color: macTheme.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: macTheme.accent,
                            width: 2,
                          ),
                          boxShadow: macTheme.popoverShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_down_doc_fill,
                              size: 56,
                              color: macTheme.accent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t.sendTab.placeItems,
                              style: MacosTypography.title2(color: macTheme.textPrimary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Drop files or folders here to send instantly',
                              style: MacosTypography.callout(color: macTheme.textSecondary),
                            ),
                          ],
                        ),
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
