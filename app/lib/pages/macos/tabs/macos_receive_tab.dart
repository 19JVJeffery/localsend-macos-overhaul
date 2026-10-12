import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/model/persistence/receive_history_entry.dart';
import 'package:localsend_app/pages/macos/common/macos_badge.dart';
import 'package:localsend_app/pages/macos/common/macos_button.dart';
import 'package:localsend_app/pages/macos/common/macos_card.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';
import 'package:localsend_app/pages/web_share_page.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/receive_history_provider.dart';
import 'package:localsend_app/provider/selection/selected_receiving_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/ip_helper.dart';
import 'package:localsend_app/util/native/directories.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/native/open_folder.dart';
import 'package:localsend_app/util/native/pick_directory_path.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:localsend_isolates/util/file_size_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class MacosReceiveTab extends StatefulWidget {
  const MacosReceiveTab({super.key});

  @override
  State<MacosReceiveTab> createState() => _MacosReceiveTabState();
}

class _MacosReceiveTabState extends State<MacosReceiveTab> {
  bool _showAdvancedNetwork = false;
  bool _copiedAlias = false;

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);
    final ref = context.ref;
    final serverState = context.watch(serverProvider);
    final isOnline = serverState != null;
    final alias = context.watch(settingsProvider.select((s) => s.alias));
    final port = context.watch(settingsProvider.select((s) => s.port));
    final destination = context.watch(settingsProvider.select((s) => s.destination));
    final quickSave = context.watch(settingsProvider.select((s) => s.quickSave));
    final quickSaveFavorites = context.watch(settingsProvider.select((s) => s.quickSaveFromFavorites));
    final localIps = context.watch(localIpProvider.select((s) => s.localIps));
    final recentHistory = context.watch(receiveHistoryProvider.select((list) => list.take(5).toList()));

    final activeSession = serverState?.session;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Incoming Session Card (if any pending)
                if (activeSession != null) ...[
                  _buildActiveSessionBanner(context, macTheme, activeSession, ref),
                  const SizedBox(height: 16),
                ],

                // Ready to Receive Hero Card
                _buildReadinessCard(context, macTheme, isOnline, serverState?.alias ?? alias, localIps, ref),
                const SizedBox(height: 16),

                // Destination Folder & Save Preferences
                _buildSaveDestinationCard(context, macTheme, destination, ref),
                const SizedBox(height: 16),

                // Quick Save & Transfer Settings
                _buildQuickControlsCard(context, macTheme, quickSave, quickSaveFavorites, port, localIps, ref),
                const SizedBox(height: 20),

                // Recent Received Files
                if (recentHistory.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Recent Incoming Activity',
                        style: MacosTypography.title3(color: macTheme.textPrimary),
                      ),
                      const Spacer(),
                      MacosButton(
                        text: 'Reveal Download Folder',
                        icon: const Icon(CupertinoIcons.folder),
                        size: MacosButtonSize.small,
                        onPressed: () async {
                          final target = destination ?? await getDefaultDestinationDirectory();
                          await openFolder(folderPath: target);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRecentHistoryList(context, macTheme, recentHistory, ref),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionBanner(
    BuildContext context,
    MacosThemeData macTheme,
    dynamic session,
    Ref ref,
  ) {
    return MacosCard(
      borderColor: macTheme.accent,
      backgroundColor: macTheme.isDark ? const Color(0xFF1F2F2D) : const Color(0xFFEFF9F8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: macTheme.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.arrow_down_to_line,
              color: macTheme.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incoming Transfer from ${session.senderAlias}',
                  style: MacosTypography.headline(color: macTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.files.length} file(s) • Ready for review',
                  style: MacosTypography.subheadline(color: macTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MacosButton(
            text: 'Accept',
            variant: MacosButtonVariant.primary,
            size: MacosButtonSize.small,
            onPressed: () async {
              final selectedFiles = ref.read(selectedReceivingFilesProvider);
              await ref.notifier(serverProvider).acceptFileRequest(selectedFiles);
            },
          ),
          const SizedBox(width: 8),
          MacosButton(
            text: 'Decline',
            variant: MacosButtonVariant.secondary,
            size: MacosButtonSize.small,
            onPressed: () {
              ref.notifier(serverProvider).declineFileRequest();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessCard(
    BuildContext context,
    MacosThemeData macTheme,
    bool isOnline,
    String effectiveAlias,
    List<String> localIps,
    Ref ref,
  ) {
    return MacosCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isOnline ? macTheme.success.withValues(alpha: 0.15) : macTheme.controlBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CupertinoIcons.antenna_radiowaves_left_right,
              color: isOnline ? macTheme.success : macTheme.textTertiary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MacosStatusDot(isOnline: isOnline, size: 8),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'Ready to Receive Files' : 'Local Server Offline',
                      style: MacosTypography.title2(color: macTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Visible as ',
                      style: MacosTypography.subheadline(color: macTheme.textSecondary),
                    ),
                    Text(
                      effectiveAlias,
                      style: MacosTypography.subheadline(color: macTheme.textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: effectiveAlias));
                        setState(() => _copiedAlias = true);
                        await Future.delayed(const Duration(seconds: 2));
                        if (mounted) setState(() => _copiedAlias = false);
                      },
                      child: Text(
                        _copiedAlias ? '✓ Copied' : 'Copy',
                        style: MacosTypography.caption(color: macTheme.accent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Share via Web Link Button
          MacosButton(
            icon: const Icon(CupertinoIcons.link),
            text: 'Receive via Web Link',
            variant: MacosButtonVariant.secondary,
            size: MacosButtonSize.small,
            onPressed: () async {
              await context.push(() => const WebSharePage());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveDestinationCard(
    BuildContext context,
    MacosThemeData macTheme,
    String? destination,
    Ref ref,
  ) {
    return MacosCard(
      title: 'Download Destination',
      subtitle: 'Where incoming files will be stored on your Mac',
      child: FutureBuilder<String>(
        future: getDefaultDestinationDirectory(),
        builder: (context, snapshot) {
          final effectivePath = destination ?? snapshot.data ?? '~/Downloads';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: macTheme.isDark ? const Color(0xFF242427) : const Color(0xFFF7F7F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: macTheme.subtleBorder, width: 0.75),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.folder_fill,
                  size: 20,
                  color: macTheme.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    effectivePath,
                    style: MacosTypography.subheadline(color: macTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                MacosButton(
                  text: 'Change...',
                  size: MacosButtonSize.small,
                  onPressed: () async {
                    final selected = await pickDirectoryPath();
                    if (selected != null) {
                      await ref.notifier(settingsProvider).setDestination(selected);
                    }
                  },
                ),
                const SizedBox(width: 6),
                MacosButton(
                  text: 'Open in Finder',
                  size: MacosButtonSize.small,
                  onPressed: () async {
                    await openFolder(folderPath: effectivePath);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickControlsCard(
    BuildContext context,
    MacosThemeData macTheme,
    bool quickSave,
    bool quickSaveFavorites,
    int port,
    List<String> localIps,
    Ref ref,
  ) {
    return MacosCard(
      title: 'Receiving Preferences',
      child: Column(
        children: [
          // Quick Save Row
          _buildToggleRow(
            context,
            macTheme,
            title: 'Quick Save (Auto-Accept)',
            description: 'Automatically accept and save transfers without showing an approval prompt',
            value: quickSave,
            onChanged: (val) async {
              await ref.notifier(settingsProvider).setQuickSave(val);
            },
          ),
          Divider(color: macTheme.divider, height: 20, thickness: 0.5),
          // Quick Save from Favorites
          _buildToggleRow(
            context,
            macTheme,
            title: 'Auto-Accept from Favorites',
            description: 'Automatically accept incoming transfers only from devices you have starred',
            value: quickSaveFavorites,
            onChanged: (val) async {
              await ref.notifier(settingsProvider).setQuickSaveFromFavorites(val);
            },
          ),
          Divider(color: macTheme.divider, height: 20, thickness: 0.5),
          // Advanced Network Info Accordion
          GestureDetector(
            onTap: () => setState(() => _showAdvancedNetwork = !_showAdvancedNetwork),
            child: Row(
              children: [
                Icon(
                  _showAdvancedNetwork ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                  size: 13,
                  color: macTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Network & Port Details',
                  style: MacosTypography.subheadline(color: macTheme.textPrimary).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Port $port • Protocol v2',
                  style: MacosTypography.caption(color: macTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (_showAdvancedNetwork) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: macTheme.isDark ? const Color(0xFF222225) : const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Network Interfaces:',
                    style: MacosTypography.caption(color: macTheme.textSecondary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (localIps.isEmpty)
                    Text(
                      'No network interfaces detected',
                      style: MacosTypography.caption(color: macTheme.textTertiary),
                    )
                  else
                    ...localIps.map(
                      (ip) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• $ip (#${ip.visualId})',
                          style: MacosTypography.tabularFigures(
                            style: MacosTypography.caption(color: macTheme.textPrimary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context,
    MacosThemeData macTheme, {
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: MacosTypography.headline(color: macTheme.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: MacosTypography.subheadline(color: macTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        CupertinoSwitch(
          value: value,
          activeTrackColor: macTheme.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRecentHistoryList(
    BuildContext context,
    MacosThemeData macTheme,
    List<ReceiveHistoryEntry> entries,
    Ref ref,
  ) {
    return MacosCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: SmartFileThumbnail(
                    path: entry.path,
                    bytes: null,
                    asset: null,
                    fileType: entry.fileType,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.fileName,
                        style: MacosTypography.subheadline(color: macTheme.textPrimary).copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'From ${entry.senderAlias} • ${entry.fileSize.asReadableFileSize}',
                        style: MacosTypography.caption(color: macTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (entry.path != null) ...[
                  MacosButton(
                    text: 'Open',
                    size: MacosButtonSize.small,
                    onPressed: () async {
                      await openFile(
                        context,
                        entry.fileType,
                        entry.path!,
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  MacosButton(
                    text: 'Show in Finder',
                    size: MacosButtonSize.small,
                    onPressed: () async {
                      final file = File(entry.path!);
                      await openFolder(
                        folderPath: file.parent.path,
                        fileName: file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : null,
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
