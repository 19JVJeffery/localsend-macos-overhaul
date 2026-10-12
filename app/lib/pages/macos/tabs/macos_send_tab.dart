import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/favorite_device.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/pages/device_details_page.dart';
import 'package:localsend_app/pages/macos/common/macos_badge.dart';
import 'package:localsend_app/pages/macos/common/macos_button.dart';
import 'package:localsend_app/pages/macos/common/macos_card.dart';
import 'package:localsend_app/pages/macos/common/macos_empty_state.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';
import 'package:localsend_app/pages/tabs/send_tab_vm.dart';
import 'package:localsend_app/pages/troubleshoot_page.dart';
import 'package:localsend_app/provider/favorites_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/util/favorites.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:localsend_isolates/util/file_size_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class MacosSendTab extends StatefulWidget {
  const MacosSendTab({super.key});

  @override
  State<MacosSendTab> createState() => _MacosSendTabState();
}

class _MacosSendTabState extends State<MacosSendTab> {
  bool _isDraggingOver = false;

  IconData _deviceIcon(DeviceType type) {
    return switch (type) {
      DeviceType.mobile => CupertinoIcons.device_phone_portrait,
      DeviceType.desktop => CupertinoIcons.macwindow,
      DeviceType.web => CupertinoIcons.globe,
      DeviceType.headless => CupertinoIcons.chevron_left_slash_chevron_right,
      DeviceType.server => CupertinoIcons.tray_2,
    };
  }

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);
    final vm = context.watch(sendTabVmProvider);
    final ref = context.ref;
    final isScanning = context.watch(nearbyDevicesProvider.select((s) => s.runningIps.isNotEmpty));

    final totalSize = vm.selectedFiles.fold<int>(0, (prev, curr) => prev + curr.size);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDraggingOver = true),
      onDragExited: (_) => setState(() => _isDraggingOver = false),
      onDragDone: (event) async {
        setState(() => _isDraggingOver = false);
        final directories = event.files.where((f) => Directory(f.path).existsSync()).toList();
        final files = event.files.where((f) => !Directory(f.path).existsSync()).toList();

        for (final dir in directories) {
          await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(dir.path));
        }
        if (files.isNotEmpty) {
          await ref
              .redux(selectedSendingFilesProvider)
              .dispatchAsync(
                AddFilesAction(
                  files: files,
                  converter: CrossFileConverters.convertXFile,
                ),
              );
        }
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // File Staging / Drop Zone
                  _buildStagingArea(context, macTheme, vm, totalSize, ref),
                  const SizedBox(height: 24),
                  // Device Discovery Header & Controls
                  _buildDiscoveryHeader(context, macTheme, vm, isScanning, ref),
                  const SizedBox(height: 12),
                  // Devices Grid or Empty State
                  if (vm.nearbyDevices.isEmpty)
                    _buildNoDevicesState(context, macTheme, isScanning, ref)
                  else
                    _buildDeviceList(context, macTheme, vm, ref),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagingArea(
    BuildContext context,
    MacosThemeData macTheme,
    SendTabVm vm,
    int totalSize,
    Ref ref,
  ) {
    final isFilesEmpty = vm.selectedFiles.isEmpty;

    if (isFilesEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: _isDraggingOver ? macTheme.activeSelection : (macTheme.isDark ? const Color(0xFF242427) : const Color(0xFFFAFAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isDraggingOver ? macTheme.accent : macTheme.border,
            width: _isDraggingOver ? 2 : 1,
            style: BorderStyle.solid,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.arrow_down_doc_fill,
                  size: 22,
                  color: macTheme.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  _isDraggingOver ? 'Drop files or folders here' : 'Drop files or folders here to send',
                  style: MacosTypography.headline(color: macTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MacosButton(
                  icon: const Icon(CupertinoIcons.doc),
                  text: t.sendTab.picker.file,
                  size: MacosButtonSize.small,
                  onPressed: () async => ref.global.dispatchAsync(
                    PickFileAction(
                      option: FilePickerOption.file,
                      context: context,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MacosButton(
                  icon: const Icon(CupertinoIcons.folder),
                  text: t.sendTab.picker.folder,
                  size: MacosButtonSize.small,
                  onPressed: () async => ref.global.dispatchAsync(
                    PickFileAction(
                      option: FilePickerOption.folder,
                      context: context,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MacosButton(
                  icon: const Icon(CupertinoIcons.pencil),
                  text: t.sendTab.picker.text,
                  size: MacosButtonSize.small,
                  onPressed: () async => ref.global.dispatchAsync(
                    PickFileAction(
                      option: FilePickerOption.text,
                      context: context,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MacosButton(
                  icon: const Icon(CupertinoIcons.doc_on_clipboard),
                  text: t.sendTab.picker.clipboard,
                  size: MacosButtonSize.small,
                  onPressed: () async => ref.global.dispatchAsync(
                    PickFileAction(
                      option: FilePickerOption.clipboard,
                      context: context,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Populated Staging Area
    return MacosCard(
      title: 'Staged for Sending',
      subtitle: '${vm.selectedFiles.length} item${vm.selectedFiles.length > 1 ? 's' : ''} • ${totalSize.asReadableFileSize}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosButton(
            icon: const Icon(CupertinoIcons.plus),
            text: 'Add Files...',
            size: MacosButtonSize.small,
            onPressed: () async => ref.global.dispatchAsync(
              PickFileAction(
                option: FilePickerOption.file,
                context: context,
              ),
            ),
          ),
          const SizedBox(width: 8),
          MacosButton(
            icon: const Icon(CupertinoIcons.trash),
            text: 'Clear All',
            size: MacosButtonSize.small,
            onPressed: () => ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction()),
          ),
        ],
      ),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: vm.selectedFiles.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final file = vm.selectedFiles[index];
            return Container(
              width: 190,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: macTheme.isDark ? const Color(0xFF2C2C2F) : const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: macTheme.subtleBorder, width: 0.75),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: SmartFileThumbnail.fromCrossFile(file),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: MacosTypography.subheadline(color: macTheme.textPrimary).copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          file.size.asReadableFileSize,
                          style: MacosTypography.caption(color: macTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  MacosIconButton(
                    size: 20,
                    icon: const Icon(CupertinoIcons.xmark, size: 10),
                    tooltip: 'Remove',
                    onPressed: () => ref.redux(selectedSendingFilesProvider).dispatch(RemoveSelectedFileAction(index)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDiscoveryHeader(
    BuildContext context,
    MacosThemeData macTheme,
    SendTabVm vm,
    bool isScanning,
    Ref ref,
  ) {
    return Row(
      children: [
        Text(
          'Nearby Recipients',
          style: MacosTypography.title2(color: macTheme.textPrimary),
        ),
        const SizedBox(width: 8),
        if (isScanning)
          const SizedBox(
            width: 14,
            height: 14,
            child: CupertinoActivityIndicator(radius: 6),
          )
        else
          MacosBadge(
            text: '${vm.nearbyDevices.length}',
            color: macTheme.controlBackground,
          ),
        const Spacer(),
        // Send Mode Segmented Control
        _buildModeSelector(context, macTheme, vm),
        const SizedBox(width: 8),
        MacosIconButton(
          icon: const Icon(CupertinoIcons.number),
          tooltip: 'Send via IP Address',
          onPressed: () => vm.onTapAddress(context),
        ),
        const SizedBox(width: 4),
        MacosIconButton(
          icon: const Icon(CupertinoIcons.star),
          tooltip: 'Favorite Devices',
          onPressed: () => vm.onTapFavorite(context),
        ),
        const SizedBox(width: 4),
        MacosIconButton(
          icon: const Icon(CupertinoIcons.arrow_clockwise),
          tooltip: 'Scan for Devices',
          onPressed: () async {
            await context.global.dispatchAsync(StartSmartScan());
          },
        ),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context, MacosThemeData macTheme, SendTabVm vm) {
    return Container(
      decoration: BoxDecoration(
        color: macTheme.isDark ? const Color(0xFF2C2C2F) : const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(7),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeSegment(
            icon: CupertinoIcons.person_fill,
            label: 'Single',
            isSelected: vm.sendMode == SendMode.single,
            onTap: () => vm.onTapSendMode(context, SendMode.single),
          ),
          _ModeSegment(
            icon: CupertinoIcons.person_2_fill,
            label: 'Multiple',
            isSelected: vm.sendMode == SendMode.multiple,
            onTap: () => vm.onTapSendMode(context, SendMode.multiple),
          ),
          _ModeSegment(
            icon: CupertinoIcons.link,
            label: 'Web Link',
            isSelected: vm.sendMode == SendMode.link,
            onTap: () => vm.onTapSendMode(context, SendMode.link),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDevicesState(BuildContext context, MacosThemeData macTheme, bool isScanning, Ref ref) {
    return MacosCard(
      padding: const EdgeInsets.all(28),
      child: MacosEmptyState(
        icon: const Icon(CupertinoIcons.antenna_radiowaves_left_right),
        title: isScanning ? 'Searching for devices...' : 'No nearby devices found',
        description: isScanning
            ? 'Scanning your local Wi-Fi network for devices running LocalSend.'
            : 'Make sure LocalSend is running on other devices on the same Wi-Fi network.',
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MacosButton(
              icon: const Icon(CupertinoIcons.arrow_clockwise),
              text: 'Scan Again',
              variant: MacosButtonVariant.primary,
              size: MacosButtonSize.small,
              onPressed: () async {
                await context.global.dispatchAsync(StartSmartScan());
              },
            ),
            const SizedBox(width: 8),
            MacosButton(
              icon: const Icon(CupertinoIcons.question_circle),
              text: t.troubleshootPage.title,
              variant: MacosButtonVariant.secondary,
              size: MacosButtonSize.small,
              onPressed: () async => context.push(() => const TroubleshootPage()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, MacosThemeData macTheme, SendTabVm vm, Ref ref) {
    return Column(
      children: vm.nearbyDevices.map((device) {
        final favoriteEntry = vm.favoriteDevices.findDevice(device);
        final isFavorite = favoriteEntry != null;
        final displayName = favoriteEntry?.alias ?? device.alias;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MacosCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Device Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: macTheme.activeSelection,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Icon(
                      _deviceIcon(device.deviceType),
                      color: macTheme.accent,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Device Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: MacosTypography.headline(color: macTheme.textPrimary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFavorite) ...[
                            const SizedBox(width: 6),
                            Icon(
                              CupertinoIcons.star_fill,
                              size: 13,
                              color: macTheme.warning,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (device.deviceModel != null) ...[
                            Text(
                              device.deviceModel!,
                              style: MacosTypography.caption(color: macTheme.textSecondary),
                            ),
                            Text(' • ', style: MacosTypography.caption(color: macTheme.textTertiary)),
                          ],
                          Text(
                            device.ip ?? 'Nearby',
                            style: MacosTypography.tabularFigures(
                              style: MacosTypography.caption(color: macTheme.textTertiary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Action Buttons
                MacosIconButton(
                  icon: Icon(
                    isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                    color: isFavorite ? macTheme.warning : macTheme.textTertiary,
                    size: 16,
                  ),
                  tooltip: isFavorite ? 'Remove Favorite' : 'Add to Favorites',
                  onPressed: () async {
                    if (isFavorite) {
                      await ref
                          .redux(favoritesProvider)
                          .dispatchAsync(
                            RemoveFavoriteAction(deviceFingerprint: device.fingerprint),
                          );
                    } else {
                      await ref
                          .redux(favoritesProvider)
                          .dispatchAsync(
                            AddFavoriteAction(
                              FavoriteDevice.fromValues(
                                fingerprint: device.fingerprint,
                                ip: device.ip ?? '0.0.0.0',
                                port: device.port,
                                alias: device.alias,
                              ),
                            ),
                          );
                    }
                  },
                ),
                const SizedBox(width: 4),
                MacosIconButton(
                  icon: const Icon(CupertinoIcons.info_circle, size: 16),
                  tooltip: 'Device Details',
                  onPressed: () async {
                    await context.push(() => DeviceDetailsPage(device: device));
                  },
                ),
                const SizedBox(width: 10),
                MacosButton(
                  icon: const Icon(CupertinoIcons.paperplane_fill, size: 12),
                  text: vm.selectedFiles.isEmpty ? 'Select & Send' : 'Send',
                  variant: MacosButtonVariant.primary,
                  size: MacosButtonSize.small,
                  onPressed: () async {
                    if (vm.sendMode == SendMode.multiple) {
                      await vm.onTapDeviceMultiSend(context, device);
                    } else {
                      await vm.onTapDevice(context, device);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? (macTheme.isDark ? const Color(0xFF404045) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: isSelected && !macTheme.isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? macTheme.textPrimary : macTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style:
                  MacosTypography.caption(
                    color: isSelected ? macTheme.textPrimary : macTheme.textSecondary,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
