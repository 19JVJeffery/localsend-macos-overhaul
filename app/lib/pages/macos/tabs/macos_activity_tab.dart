import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/model/persistence/receive_history_entry.dart';
import 'package:localsend_app/pages/macos/common/macos_badge.dart';
import 'package:localsend_app/pages/macos/common/macos_button.dart';
import 'package:localsend_app/pages/macos/common/macos_card.dart';
import 'package:localsend_app/pages/macos/common/macos_empty_state.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';
import 'package:localsend_app/provider/receive_history_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/native/directories.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/native/open_folder.dart';
import 'package:localsend_app/widget/dialogs/file_info_dialog.dart';
import 'package:localsend_app/widget/dialogs/history_clear_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:localsend_isolates/util/file_size_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';

class MacosActivityTab extends StatefulWidget {
  const MacosActivityTab({super.key});

  @override
  State<MacosActivityTab> createState() => _MacosActivityTabState();
}

class _MacosActivityTabState extends State<MacosActivityTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);
    final ref = context.ref;
    final allEntries = context.watch(receiveHistoryProvider);
    final destination = context.watch(settingsProvider.select((s) => s.destination));

    final filteredEntries = _searchQuery.trim().isEmpty
        ? allEntries
        : allEntries.where((e) {
            final query = _searchQuery.toLowerCase();
            return e.fileName.toLowerCase().contains(query) || e.senderAlias.toLowerCase().contains(query);
          }).toList();

    return Column(
      children: [
        // Filter and Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: macTheme.isDark ? const Color(0xFF222225) : const Color(0xFFF9F9FB),
            border: Border(bottom: BorderSide(color: macTheme.border, width: 0.75)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: CupertinoSearchTextField(
                    placeholder: 'Filter by filename or sender...',
                    style: MacosTypography.body(color: macTheme.textPrimary),
                    backgroundColor: macTheme.searchBackground,
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              MacosButton(
                icon: const Icon(CupertinoIcons.folder),
                text: 'Downloads Folder',
                size: MacosButtonSize.small,
                onPressed: () async {
                  final target = destination ?? await getDefaultDestinationDirectory();
                  await openFolder(folderPath: target);
                },
              ),
              const SizedBox(width: 8),
              MacosButton(
                icon: const Icon(CupertinoIcons.trash),
                text: 'Clear History',
                size: MacosButtonSize.small,
                variant: MacosButtonVariant.secondary,
                onPressed: allEntries.isEmpty
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => const HistoryClearDialog(),
                        );
                        if (confirm == true) {
                          await ref.redux(receiveHistoryProvider).dispatchAsync(RemoveAllHistoryEntriesAction());
                        }
                      },
              ),
            ],
          ),
        ),
        // History List or Empty State
        Expanded(
          child: filteredEntries.isEmpty
              ? MacosEmptyState(
                  icon: const Icon(CupertinoIcons.clock),
                  title: _searchQuery.isNotEmpty ? 'No Matching Transfers' : 'No Transfer Activity',
                  description: _searchQuery.isNotEmpty
                      ? 'No transfers match "$_searchQuery".'
                      : 'Incoming files and messages received via LocalSend will be listed here.',
                  action: _searchQuery.isNotEmpty
                      ? MacosButton(
                          text: 'Clear Filter',
                          size: MacosButtonSize.small,
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredEntries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    return _HistoryRowCard(entry: entry);
                  },
                ),
        ),
      ],
    );
  }
}

class _HistoryRowCard extends StatelessWidget {
  final ReceiveHistoryEntry entry;

  const _HistoryRowCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);
    final ref = context.ref;

    return MacosCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: SmartFileThumbnail(
              path: entry.path,
              bytes: null,
              asset: null,
              fileType: entry.fileType,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.fileName,
                        style: MacosTypography.headline(color: macTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    MacosBadge(
                      text: entry.isMessage ? 'Message' : 'Received',
                      color: entry.isMessage ? macTheme.warning.withValues(alpha: 0.15) : macTheme.success.withValues(alpha: 0.15),
                      textColor: entry.isMessage ? macTheme.warning : macTheme.success,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'From ${entry.senderAlias}',
                      style: MacosTypography.caption(color: macTheme.textSecondary),
                    ),
                    Text(' • ', style: MacosTypography.caption(color: macTheme.textTertiary)),
                    Text(
                      entry.fileSize.asReadableFileSize,
                      style: MacosTypography.tabularFigures(
                        style: MacosTypography.caption(color: macTheme.textSecondary),
                      ),
                    ),
                    Text(' • ', style: MacosTypography.caption(color: macTheme.textTertiary)),
                    Text(
                      entry.timestampString(context),
                      style: MacosTypography.caption(color: macTheme.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Actions
          if (entry.path != null) ...[
            MacosButton(
              text: 'Open',
              size: MacosButtonSize.small,
              onPressed: () async {
                await openFile(
                  context,
                  entry.fileType,
                  entry.path!,
                  onDeleteTap: () => ref.redux(receiveHistoryProvider).dispatchAsync(RemoveHistoryEntryAction(entry.id)),
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
            const SizedBox(width: 6),
          ],
          MacosIconButton(
            icon: const Icon(CupertinoIcons.info_circle, size: 16),
            tooltip: 'File Information',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => FileInfoDialog(entry: entry),
              );
            },
          ),
          const SizedBox(width: 4),
          MacosIconButton(
            icon: Icon(CupertinoIcons.trash, size: 15, color: macTheme.error),
            tooltip: 'Remove from History',
            onPressed: () async {
              await ref.redux(receiveHistoryProvider).dispatchAsync(RemoveHistoryEntryAction(entry.id));
            },
          ),
        ],
      ),
    );
  }
}
