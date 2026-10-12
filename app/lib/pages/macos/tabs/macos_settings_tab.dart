import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/pages/about/about_page.dart';
import 'package:localsend_app/pages/changelog_page.dart';
import 'package:localsend_app/pages/macos/common/macos_button.dart';
import 'package:localsend_app/pages/macos/common/macos_card.dart';
import 'package:localsend_app/pages/macos/theme/macos_theme.dart';
import 'package:localsend_app/pages/macos/theme/macos_typography.dart';
import 'package:localsend_app/pages/settings/network_interfaces_page.dart';
import 'package:localsend_app/pages/tabs/settings_tab_controller.dart';
import 'package:localsend_app/pages/tabs/settings_tab_vm.dart';
import 'package:localsend_app/pages/troubleshoot_page.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/security_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/version_provider.dart';
import 'package:localsend_app/util/alias_generator.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/util/i18n.dart';
import 'package:localsend_app/util/native/macos_channel.dart';
import 'package:localsend_app/util/native/pick_directory_path.dart';
import 'package:localsend_app/widget/dialogs/encryption_disabled_notice.dart';
import 'package:localsend_app/widget/dialogs/pin_dialog.dart';
import 'package:localsend_app/widget/dialogs/quick_save_from_favorites_notice.dart';
import 'package:localsend_app/widget/dialogs/quick_save_notice.dart';
import 'package:localsend_app/widget/local_send_logo.dart';
import 'package:localsend_isolates/constants.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:url_launcher/url_launcher.dart';

enum _SettingsCategory {
  general(CupertinoIcons.gear_alt_fill, 'General'),
  receive(CupertinoIcons.arrow_down_circle_fill, 'Receiving'),
  network(CupertinoIcons.wifi, 'Network'),
  security(CupertinoIcons.lock_shield_fill, 'Security & Privacy'),
  about(CupertinoIcons.info_circle_fill, 'About')
  ;

  final IconData icon;
  final String label;

  const _SettingsCategory(this.icon, this.label);
}

class MacosSettingsTab extends StatefulWidget {
  const MacosSettingsTab({super.key});

  @override
  State<MacosSettingsTab> createState() => _MacosSettingsTabState();
}

class _MacosSettingsTabState extends State<MacosSettingsTab> {
  _SettingsCategory _selectedCategory = _SettingsCategory.general;

  @override
  Widget build(BuildContext context) {
    final macTheme = MacosTheme.of(context);

    return ViewModelBuilder(
      provider: (ref) => settingsTabControllerProvider,
      builder: (context, vm) {
        final ref = context.ref;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Category Navigation (macOS System Settings Style)
            Container(
              width: 190,
              decoration: BoxDecoration(
                color: macTheme.sidebarBackground.withValues(alpha: 0.6),
                border: Border(
                  right: BorderSide(color: macTheme.border, width: 0.75),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Column(
                children: [
                  ..._SettingsCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? macTheme.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                cat.icon,
                                size: 15,
                                color: isSelected ? Colors.white : macTheme.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.label,
                                  style:
                                      MacosTypography.body(
                                        color: isSelected ? Colors.white : macTheme.textPrimary,
                                      ).copyWith(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  // Advanced Settings Switch
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: macTheme.isDark ? const Color(0xFF2C2C2F) : const Color(0xFFE4E4EA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Advanced',
                            style: MacosTypography.caption(color: macTheme.textPrimary).copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: vm.advanced,
                          activeTrackColor: macTheme.accent,
                          onChanged: (b) => vm.onTapAdvanced(b),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Right Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: switch (_selectedCategory) {
                      _SettingsCategory.general => _buildGeneralSettings(context, macTheme, vm, ref),
                      _SettingsCategory.receive => _buildReceiveSettings(context, macTheme, vm, ref),
                      _SettingsCategory.network => _buildNetworkSettings(context, macTheme, vm, ref),
                      _SettingsCategory.security => _buildSecuritySettings(context, macTheme, vm, ref),
                      _SettingsCategory.about => _buildAboutSettings(context, macTheme, vm, ref),
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGeneralSettings(
    BuildContext context,
    MacosThemeData macTheme,
    SettingsTabVm vm,
    Ref ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Appearance & Display'),
        MacosCard(
          child: Column(
            children: [
              _buildSettingRow(
                macTheme,
                title: t.settingsTab.general.brightness,
                description: 'Follow macOS system appearance or specify dark/light mode',
                control: CupertinoSlidingSegmentedControl<ThemeMode>(
                  groupValue: vm.settings.theme,
                  children: {
                    for (final theme in vm.themeModes)
                      theme: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(theme.humanName, style: MacosTypography.caption(color: macTheme.textPrimary)),
                      ),
                  },
                  onValueChanged: (theme) {
                    if (theme != null) vm.onChangeTheme(context, theme);
                  },
                ),
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildSettingRow(
                macTheme,
                title: t.settingsTab.general.color,
                description: 'Accent theme color mode',
                control: DropdownButton<ColorMode>(
                  value: vm.settings.colorMode,
                  underline: const SizedBox(),
                  dropdownColor: macTheme.cardBackground,
                  items: vm.colorModes.map((colorMode) {
                    return DropdownMenuItem(
                      value: colorMode,
                      child: Text(
                        colorMode.humanName,
                        style: MacosTypography.subheadline(color: macTheme.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (colorMode) {
                    if (colorMode != null) vm.onChangeColorMode(context, colorMode);
                  },
                ),
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildSettingRow(
                macTheme,
                title: t.settingsTab.general.language,
                description: 'Application language',
                control: MacosButton(
                  text: vm.settings.locale?.getLocaleName() ?? t.settingsTab.general.languageOptions.system,
                  size: MacosButtonSize.small,
                  onPressed: () => vm.onTapLanguage(context),
                ),
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildToggleSettingRow(
                macTheme,
                title: t.settingsTab.general.animations,
                description: 'Enable smooth user interface transitions',
                value: vm.settings.enableAnimations,
                onChanged: (b) => ref.notifier(settingsProvider).setEnableAnimations(b),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('macOS Desktop Integration'),
        MacosCard(
          child: Column(
            children: [
              _buildToggleSettingRow(
                macTheme,
                title: t.settingsTab.general.launchAtStartup,
                description: 'Automatically launch LocalSend when you log into your Mac',
                value: vm.autoStart,
                onChanged: (_) => vm.onToggleAutoStart(context),
              ),
              if (vm.autoStart) ...[
                Divider(color: macTheme.divider, height: 24, thickness: 0.5),
                _buildToggleSettingRow(
                  macTheme,
                  title: t.settingsTab.general.launchMinimized,
                  description: 'Start hidden in the menu bar on login',
                  value: vm.autoStartLaunchHidden,
                  onChanged: (_) => vm.onToggleAutoStartLaunchHidden(context),
                ),
              ],
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildToggleSettingRow(
                macTheme,
                title: t.settingsTab.general.minimizeToTray,
                description: 'Keep LocalSend running in the macOS menu bar when window is closed',
                value: vm.settings.minimizeToTray,
                onChanged: (b) => ref.notifier(settingsProvider).setMinimizeToTray(b),
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildToggleSettingRow(
                macTheme,
                title: t.settingsTab.general.alwaysOnTop,
                description: 'Keep LocalSend window floating on top of other Mac apps',
                value: vm.settings.alwaysOnTop,
                onChanged: (b) => ref.notifier(settingsProvider).setAlwaysOnTop(b),
              ),
              if (vm.advanced) ...[
                Divider(color: macTheme.divider, height: 24, thickness: 0.5),
                _buildToggleSettingRow(
                  macTheme,
                  title: t.settingsTab.general.saveWindowPlacement,
                  description: 'Remember window size and position across sessions',
                  value: vm.settings.saveWindowPlacement,
                  onChanged: (b) => ref.notifier(settingsProvider).setSaveWindowPlacement(b),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiveSettings(
    BuildContext context,
    MacosThemeData macTheme,
    SettingsTabVm vm,
    Ref ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Storage & Destinations'),
        MacosCard(
          child: Column(
            children: [
              _buildSettingRow(
                macTheme,
                title: t.settingsTab.receive.destination,
                description: vm.settings.destination ?? 'Default (Downloads folder)',
                control: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MacosButton(
                      text: 'Select Folder...',
                      size: MacosButtonSize.small,
                      onPressed: () async {
                        final directory = await pickDirectoryPath();
                        if (directory != null) {
                          await persistDestinationFolderAccess(directory);
                          await ref.notifier(settingsProvider).setDestination(directory);
                        }
                      },
                    ),
                    if (vm.settings.destination != null) ...[
                      const SizedBox(width: 6),
                      MacosButton(
                        text: 'Reset',
                        size: MacosButtonSize.small,
                        onPressed: () async {
                          await removeExistingDestinationAccess();
                          await ref.notifier(settingsProvider).setDestination(null);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildToggleSettingRow(
                macTheme,
                title: t.settingsTab.receive.saveToHistory,
                description: 'Record completed file transfers in the Transfers view',
                value: vm.settings.saveToHistory,
                onChanged: (b) => ref.notifier(settingsProvider).setSaveToHistory(b),
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildToggleSettingRow(
                macTheme,
                title: t.settingsTab.receive.autoFinish,
                description: 'Automatically close transfer sheet when all files finish transferring',
                value: vm.settings.autoFinish,
                onChanged: (b) => ref.notifier(settingsProvider).setAutoFinish(b),
              ),
              if (vm.advanced) ...[
                Divider(color: macTheme.divider, height: 24, thickness: 0.5),
                _buildToggleSettingRow(
                  macTheme,
                  title: t.settingsTab.receive.verifyChecksums,
                  description: 'Cryptographically verify file checksums after transfer',
                  value: vm.settings.verifyChecksums,
                  onChanged: (b) async {
                    await ref.notifier(settingsProvider).setVerifyChecksums(b);
                    if (ref.read(serverProvider) != null) {
                      await ref.notifier(serverProvider).restartServerFromSettings();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Automated Approval'),
        MacosCard(
          child: Column(
            children: [
              _buildToggleSettingRow(
                macTheme,
                title: t.settingsTab.receive.quickSave,
                description: 'Automatically accept file transfers from any device on the network',
                value: vm.settings.quickSave,
                onChanged: (b) async {
                  final old = vm.settings.quickSave;
                  await ref.notifier(settingsProvider).setQuickSave(b);
                  if (b) {
                    await ref.notifier(settingsProvider).setQuickSaveFromFavorites(false);
                  }
                  if (!old && b && context.mounted) {
                    await QuickSaveNotice.open(context);
                  }
                },
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildToggleSettingRow(
                macTheme,
                title: t.settingsTab.receive.quickSaveFromFavorites,
                description: 'Automatically accept file transfers only from favorited devices',
                value: vm.settings.quickSaveFromFavorites,
                onChanged: (b) async {
                  final old = vm.settings.quickSaveFromFavorites;
                  await ref.notifier(settingsProvider).setQuickSaveFromFavorites(b);
                  if (b) {
                    await ref.notifier(settingsProvider).setQuickSave(false);
                  }
                  if (!old && b && context.mounted) {
                    await QuickSaveFromFavoritesNotice.open(context);
                  }
                },
              ),
              if (vm.advanced) ...[
                Divider(color: macTheme.divider, height: 24, thickness: 0.5),
                _buildToggleSettingRow(
                  macTheme,
                  title: t.settingsTab.send.shareViaLinkAutoAccept,
                  description: 'Automatically accept file transfers uploaded via the Web browser link',
                  value: vm.settings.shareViaLinkAutoAccept,
                  onChanged: (b) => ref.notifier(settingsProvider).setShareViaLinkAutoAccept(b),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkSettings(
    BuildContext context,
    MacosThemeData macTheme,
    SettingsTabVm vm,
    Ref ref,
  ) {
    final serverRunning = vm.serverState != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Server & Protocol Status'),
        MacosCard(
          child: Column(
            children: [
              _buildSettingRow(
                macTheme,
                title: 'HTTP / Multicast Server',
                description: serverRunning ? 'Running on port ${vm.settings.port}' : 'Server stopped',
                control: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!serverRunning)
                      MacosButton(
                        text: 'Start Server',
                        icon: const Icon(CupertinoIcons.play_fill),
                        variant: MacosButtonVariant.primary,
                        size: MacosButtonSize.small,
                        onPressed: () => vm.onTapStartServer(context),
                      )
                    else ...[
                      MacosButton(
                        text: 'Restart',
                        icon: const Icon(CupertinoIcons.arrow_clockwise),
                        size: MacosButtonSize.small,
                        onPressed: () => vm.onTapRestartServer(context),
                      ),
                      const SizedBox(width: 6),
                      MacosButton(
                        text: 'Stop',
                        icon: const Icon(CupertinoIcons.stop_fill),
                        variant: MacosButtonVariant.destructive,
                        size: MacosButtonSize.small,
                        onPressed: vm.onTapStopServer,
                      ),
                    ],
                  ],
                ),
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildSettingRow(
                macTheme,
                title: 'Server Port',
                description: 'Default is $defaultPort. Changing requires server restart.',
                control: SizedBox(
                  width: 90,
                  height: 28,
                  child: CupertinoTextField(
                    controller: vm.portController,
                    style: MacosTypography.tabularFigures(
                      style: MacosTypography.subheadline(color: macTheme.textPrimary),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (s) async {
                      final p = int.tryParse(s);
                      if (p != null) await ref.notifier(settingsProvider).setPort(p);
                    },
                  ),
                ),
              ),
              if (vm.advanced) ...[
                Divider(color: macTheme.divider, height: 24, thickness: 0.5),
                _buildSettingRow(
                  macTheme,
                  title: 'Network Interfaces',
                  description: 'Select which network interfaces to listen on',
                  control: MacosButton(
                    text: 'Configure...',
                    size: MacosButtonSize.small,
                    onPressed: () async => context.push(() => const NetworkInterfacesPage()),
                  ),
                ),
                Divider(color: macTheme.divider, height: 24, thickness: 0.5),
                _buildSettingRow(
                  macTheme,
                  title: 'Multicast Group',
                  description: 'UDP Multicast discovery address',
                  control: SizedBox(
                    width: 140,
                    height: 28,
                    child: CupertinoTextField(
                      controller: vm.multicastController,
                      style: MacosTypography.caption(color: macTheme.textPrimary),
                      onChanged: (s) => ref.notifier(settingsProvider).setMulticastGroup(s),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings(
    BuildContext context,
    MacosThemeData macTheme,
    SettingsTabVm vm,
    Ref ref,
  ) {
    final certHash = context.watch(securityProvider.select((s) => s.certificateHash));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Device Identity'),
        MacosCard(
          child: Column(
            children: [
              _buildSettingRow(
                macTheme,
                title: 'Device Alias (Name)',
                description: 'Name shown to other LocalSend devices on the network',
                control: SizedBox(
                  width: 220,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: vm.aliasController,
                          style: MacosTypography.subheadline(color: macTheme.textPrimary),
                          onChanged: (s) => ref.notifier(settingsProvider).setAlias(s),
                        ),
                      ),
                      const SizedBox(width: 4),
                      MacosIconButton(
                        size: 26,
                        icon: const Icon(CupertinoIcons.sparkles),
                        tooltip: 'Generate Random Name',
                        onPressed: () async {
                          final newAlias = generateRandomAlias();
                          vm.aliasController.text = newAlias;
                          await ref.notifier(settingsProvider).setAlias(newAlias);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildSettingRow(
                macTheme,
                title: 'Device Type',
                description: 'Icon and identity presented to other devices',
                control: DropdownButton<DeviceType>(
                  value: vm.deviceInfo.deviceType,
                  underline: const SizedBox(),
                  dropdownColor: macTheme.cardBackground,
                  items: DeviceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 16, color: macTheme.accent),
                          const SizedBox(width: 6),
                          Text(type.name, style: MacosTypography.subheadline(color: macTheme.textPrimary)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (t) async {
                    if (t != null) await ref.notifier(settingsProvider).setDeviceType(t);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Security & Encryption'),
        MacosCard(
          child: Column(
            children: [
              _buildToggleSettingRow(
                macTheme,
                title: 'Require PIN Code',
                description: vm.settings.receivePin != null
                    ? 'Active PIN: ${vm.settings.receivePin}'
                    : 'Request a PIN code before accepting transfers',
                value: vm.settings.receivePin != null,
                onChanged: (b) async {
                  if (vm.settings.receivePin != null) {
                    await ref.notifier(settingsProvider).setReceivePin(null);
                  } else {
                    final String? newPin = await showDialog<String>(
                      context: context,
                      builder: (_) => const PinDialog(obscureText: false, generateRandom: false),
                    );
                    if (newPin != null && newPin.isNotEmpty) {
                      await ref.notifier(settingsProvider).setReceivePin(newPin);
                    }
                  }
                  if (ref.read(serverProvider) != null) {
                    await ref.notifier(serverProvider).restartServerFromSettings();
                  }
                },
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildToggleSettingRow(
                macTheme,
                title: 'Mutual TLS Encryption',
                description: 'End-to-end encryption with on-the-fly client certificates',
                value: vm.settings.https,
                onChanged: (b) async {
                  final old = vm.settings.https;
                  await ref.notifier(settingsProvider).setHttps(b);
                  if (old && !b && context.mounted) {
                    await EncryptionDisabledNotice.open(context);
                  }
                },
              ),
              if (certHash.isNotEmpty) ...[
                Divider(color: macTheme.divider, height: 24, thickness: 0.5),
                _buildSettingRow(
                  macTheme,
                  title: 'Certificate Fingerprint',
                  description: certHash,
                  control: MacosButton(
                    text: 'Copy',
                    size: MacosButtonSize.small,
                    onPressed: () => Clipboard.setData(ClipboardData(text: certHash)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSettings(
    BuildContext context,
    MacosThemeData macTheme,
    SettingsTabVm vm,
    Ref ref,
  ) {
    final version = context.watch(versionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MacosCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: LocalSendLogo(withText: false),
              ),
              const SizedBox(height: 12),
              Text(
                'LocalSend for macOS',
                style: MacosTypography.title1(color: macTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Version $version • AirDrop across every platform',
                style: MacosTypography.subheadline(color: macTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MacosButton(
                    icon: const Icon(CupertinoIcons.globe),
                    text: 'Website',
                    size: MacosButtonSize.small,
                    onPressed: () => launchUrl(Uri.parse('https://localsend.org')),
                  ),
                  const SizedBox(width: 8),
                  MacosButton(
                    icon: const Icon(CupertinoIcons.chevron_left_slash_chevron_right),
                    text: 'GitHub',
                    size: MacosButtonSize.small,
                    onPressed: () => launchUrl(Uri.parse('https://github.com/localsend/localsend')),
                  ),
                  const SizedBox(width: 8),
                  MacosButton(
                    icon: const Icon(CupertinoIcons.question_circle),
                    text: 'Troubleshoot',
                    size: MacosButtonSize.small,
                    onPressed: () => context.push(() => const TroubleshootPage()),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MacosCard(
          child: Column(
            children: [
              _buildSettingRow(
                macTheme,
                title: t.aboutPage.title,
                description: 'Open source contributors & licenses',
                control: MacosButton(
                  text: 'View...',
                  size: MacosButtonSize.small,
                  onPressed: () => context.push(() => const AboutPage()),
                ),
              ),
              Divider(color: macTheme.divider, height: 24, thickness: 0.5),
              _buildSettingRow(
                macTheme,
                title: t.changelogPage.title,
                description: 'Release history and updates',
                control: MacosButton(
                  text: 'View...',
                  size: MacosButtonSize.small,
                  onPressed: () => context.push(() => const ChangelogPage()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: MacosTypography.caption(color: Colors.grey).copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    MacosThemeData macTheme, {
    required String title,
    required String description,
    required Widget control,
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
        control,
      ],
    );
  }

  Widget _buildToggleSettingRow(
    MacosThemeData macTheme, {
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingRow(
      macTheme,
      title: title,
      description: description,
      control: CupertinoSwitch(
        value: value,
        activeTrackColor: macTheme.accent,
        onChanged: onChanged,
      ),
    );
  }
}

extension on ThemeMode {
  String get humanName {
    switch (this) {
      case ThemeMode.system:
        return t.settingsTab.general.brightnessOptions.system;
      case ThemeMode.light:
        return t.settingsTab.general.brightnessOptions.light;
      case ThemeMode.dark:
        return t.settingsTab.general.brightnessOptions.dark;
    }
  }
}

extension on ColorMode {
  String get humanName {
    return switch (this) {
      ColorMode.system => t.settingsTab.general.colorOptions.system,
      ColorMode.localsend => t.appName,
      ColorMode.oled => t.settingsTab.general.colorOptions.oled,
      ColorMode.yaru => 'Yaru',
      ColorMode.custom => t.settingsTab.general.colorOptions.custom,
    };
  }
}
