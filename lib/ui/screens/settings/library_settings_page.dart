import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:m3e_dropdown_menu/m3e_dropdown_menu.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/screens/settings/controllers/library_settings_controller.dart';

class LibrarySettingsPage extends StatefulWidget {
  const LibrarySettingsPage({super.key});

  @override
  State<LibrarySettingsPage> createState() => _LibrarySettingsPageState();
}

class _LibrarySettingsPageState extends State<LibrarySettingsPage> {
  late final LibrarySettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LibrarySettingsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final music = context.read<MusicProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainer,
          appBar: AppBar(
            title: const Text('Library Settings'),
            centerTitle: true,
            scrolledUnderElevation: 0,
            backgroundColor: colorScheme.surfaceContainer,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            physics: const BouncingScrollPhysics(),
            children: [
              const NixSectionHeader(title: 'Organization', topPadding: 16),
              CardListTileWithChild(
                title: 'Filter Short Audio',
                subtitle:
                    'Minimum length: ${_controller.getDurationLabel(settings.minDuration)}',
                icon: FlutterRemix.filter_line,
                isFirst: true,
                child: M3EDropdownMenu<String>(
                  items: [
                    M3EDropdownItem<String>(
                      label: 'Off (Show All)',
                      value: '0',
                      selected: settings.minDuration == 0,
                    ),
                    M3EDropdownItem<String>(
                      label: '30 seconds',
                      value: '30',
                      selected: settings.minDuration == 30,
                    ),
                    M3EDropdownItem<String>(
                      label: '1 minute (Default)',
                      value: '60',
                      selected: settings.minDuration == 60,
                    ),
                    M3EDropdownItem<String>(
                      label: '2 minutes',
                      value: '120',
                      selected: settings.minDuration == 120,
                    ),
                  ],
                  singleSelect: true,
                  searchEnabled: false,
                  showChipAnimation: true,
                  maxSelections: 3,
                  enabled: true,
                  containerRadius: 16.0,
                  haptic: M3EHapticFeedback.light,
                  openMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.6),
                  closeMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.6),
                  fieldStyle: M3EDropdownFieldStyle(
                    hintText: 'Select Duration',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    selectedTextStyle: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    showClearIcon: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 10.0,
                    ),
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    foregroundColor: colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  dropdownStyle: M3EDropdownStyle(
                    elevation: 0.0,
                    maxHeight: 350.0,
                    marginTop: 6.0,
                    containerRadius: 16.0,
                    expandDirection: ExpandDirection.auto,
                    contentPadding: const EdgeInsets.all(6.0),
                    backgroundColor: colorScheme.surfaceContainerHigh,
                  ),
                  chipStyle: M3EChipStyle(
                    backgroundColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                    spacing: 6.0,
                    runSpacing: 6.0,
                    wrap: true,
                    maxDisplayCount: 3,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    openMotion: M3EMotion.custom(
                      stiffness: 500.0,
                      damping: 0.6,
                    ),
                    closeMotion: M3EMotion.custom(
                      stiffness: 500.0,
                      damping: 0.6,
                    ),
                  ),
                  itemStyle: M3EDropdownItemStyle(
                    backgroundColor: colorScheme.surfaceContainer,
                    selectedBackgroundColor: colorScheme.primaryContainer,
                    textColor: colorScheme.onSurface,
                    selectedTextColor: colorScheme.onPrimaryContainer,
                    selectedTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    outerRadius: 14.0,
                    innerRadius: 6.0,
                    itemGap: 3.0,
                    itemPadding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    selectedIcon: Icon(
                      Icons.check_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  closeOnBackButton: false,
                  onSelectionChanged: (selectedItems) async {
                    if (selectedItems.isNotEmpty) {
                      final selectedValue =
                          int.tryParse(selectedItems.first.value) ?? 60;
                      settings.setMinDuration(selectedValue);
                      await music.scanDevice();
                    }
                  },
                ),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Scan Media',
                subtitle: 'Manually refresh your music library',
                icon: FlutterRemix.refresh_line,
                isLast: true,
                onTap: () => _controller.scanDevice(context, music),
              ),
              const NixSectionHeader(title: 'Search & History', topPadding: 32),
              CardListTile(
                title: 'Clear Search History',
                subtitle: 'Delete all previous search queries',
                icon: FlutterRemix.history_line,
                isFirst: true,
                isLast: true,
                onTap: () =>
                    _controller.showClearSearchConfirmation(context, settings),
              ),
              const NixSectionHeader(title: 'Danger Zone', topPadding: 32),
              CardListTile(
                title: 'Reset Library Database',
                subtitle: 'Clear all history, favorites, and re-scan',
                icon: FlutterRemix.delete_bin_line,
                isFirst: true,
                isLast: true,
                onTap: () => _controller.showResetConfirmation(context, music),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 24, right: 12),
                child: Text(
                  'Use Filter Short Audio to hide ringtones, voice notes, or app sounds. Higher values ensure only your real tracks appear in your library.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
              const NixBottomSpacer(),
            ],
          ),
        );
      },
    );
  }
}
