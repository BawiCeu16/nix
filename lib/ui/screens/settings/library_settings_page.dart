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
              NixCardExpansionTile(
                title: 'Save Ascending & Sort',
                isFirst: true,
                icon: FlutterRemix.filter_3_line,
                showExpansionIcon: settings.saveAscending || settings.saveSort,
                initiallyExpanded: false,
                trailing: Switch(
                  value: settings.saveAscending || settings.saveSort,
                  onChanged: (value) {
                    settings.setSaveAscending(value);
                    settings.setSaveSort(value);
                  },
                ),
                children: [
                  if (settings.saveAscending || settings.saveSort) ...[
                    const SizedBox(height: 2.5),
                    CardListTileWithChild(
                      title: 'Preferences to Save',
                      icon: FlutterRemix.list_check,
                      child: M3EDropdownMenu<String>(
                        items: [
                          M3EDropdownItem<String>(
                            label: 'Ascending and Sort',
                            value: 'both',
                            selected:
                                settings.saveAscending && settings.saveSort,
                          ),
                          M3EDropdownItem<String>(
                            label: 'Ascending',
                            value: 'ascending',
                            selected:
                                settings.saveAscending && !settings.saveSort,
                          ),
                          M3EDropdownItem<String>(
                            label: 'Sort',
                            value: 'sort',
                            selected:
                                !settings.saveAscending && settings.saveSort,
                          ),
                        ],
                        singleSelect: true,
                        searchEnabled: false,
                        showChipAnimation: true,
                        maxSelections: 1,
                        enabled: true,
                        containerRadius: 16.0,
                        haptic: M3EHapticFeedback.light,
                        openMotion: M3EMotion.custom(
                          stiffness: 500.0,
                          damping: 0.6,
                        ),
                        closeMotion: M3EMotion.custom(
                          stiffness: 500.0,
                          damping: 0.6,
                        ),
                        fieldStyle: M3EDropdownFieldStyle(
                          hintText: 'Select Option',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
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
                          deleteIcon: Icon(
                            Icons.close,
                            size: 16,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          spacing: 6.0,
                          runSpacing: 6.0,
                          wrap: true,
                          maxDisplayCount: 1,
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
                        onSelectionChanged: (selectedItems) {
                          if (selectedItems.isNotEmpty) {
                            final selectedValue = selectedItems.first.value;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (selectedValue == 'both') {
                                if (!settings.saveAscending ||
                                    !settings.saveSort) {
                                  settings.setSaveAscending(true);
                                  settings.setSaveSort(true);
                                }
                              } else if (selectedValue == 'ascending') {
                                if (!settings.saveAscending ||
                                    settings.saveSort) {
                                  settings.setSaveAscending(true);
                                  settings.setSaveSort(false);
                                }
                              } else if (selectedValue == 'sort') {
                                if (settings.saveAscending ||
                                    !settings.saveSort) {
                                  settings.setSaveAscending(false);
                                  settings.setSaveSort(true);
                                }
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2.5),
              CardListTileWithChild(
                title: 'Filter Short Audio',
                subtitle:
                    'Minimum length: ${_controller.getDurationLabel(settings.minDuration)}',
                icon: FlutterRemix.timer_line,
                isLast: true,
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
                  maxSelections: 1,
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
                    deleteIcon: Icon(
                      Icons.close,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                    spacing: 6.0,
                    runSpacing: 6.0,
                    wrap: true,
                    maxDisplayCount: 1,
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
                  onSelectionChanged: (selectedItems) {
                    if (selectedItems.isNotEmpty) {
                      final selectedValue =
                          int.tryParse(selectedItems.first.value) ?? 60;
                      if (selectedValue != settings.minDuration) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          settings.setMinDuration(selectedValue);
                          await music.scanDevice();
                        });
                      }
                    }
                  },
                ),
              ),

              const NixSectionHeader(title: 'Display & Layout', topPadding: 24),
              CardListTileWithChild(
                title: 'Artist Grid Columns',
                subtitle: '${settings.artistGridCrossAxisCount} Columns',
                icon: FlutterRemix.layout_grid_line,
                isFirst: true,
                isLast: true,
                child: M3EDropdownMenu<String>(
                  items: [
                    M3EDropdownItem<String>(
                      label: '2 Columns (Default)',
                      value: '2',
                      selected: settings.artistGridCrossAxisCount == 2,
                    ),
                    M3EDropdownItem<String>(
                      label: '3 Columns',
                      value: '3',
                      selected: settings.artistGridCrossAxisCount == 3,
                    ),
                    M3EDropdownItem<String>(
                      label: '4 Columns',
                      value: '4',
                      selected: settings.artistGridCrossAxisCount == 4,
                    ),
                  ],
                  singleSelect: true,
                  searchEnabled: false,
                  showChipAnimation: true,
                  maxSelections: 1,
                  enabled: true,
                  containerRadius: 16.0,
                  haptic: M3EHapticFeedback.light,
                  openMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.6),
                  closeMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.6),
                  fieldStyle: M3EDropdownFieldStyle(
                    hintText: 'Select Columns',
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
                    deleteIcon: Icon(
                      Icons.close,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                    spacing: 6.0,
                    runSpacing: 6.0,
                    wrap: true,
                    maxDisplayCount: 1,
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
                  onSelectionChanged: (selectedItems) {
                    if (selectedItems.isNotEmpty) {
                      final selectedValue =
                          int.tryParse(selectedItems.first.value) ?? 2;
                      if (selectedValue != settings.artistGridCrossAxisCount) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          settings.setArtistGridCrossAxisCount(selectedValue);
                        });
                      }
                    }
                  },
                ),
              ),

              const NixSectionHeader(
                title: 'Library Management',
                topPadding: 24,
              ),
              CardListTile(
                title: 'Scan Media',
                icon: FlutterRemix.refresh_line,
                isFirst: true,
                isLast: true,
                onTap: () => _controller.scanDevice(context, music),
              ),

              const NixSectionHeader(title: 'Danger Zone', topPadding: 32),
              CardListTile(
                title: 'Clear Search History',
                icon: FlutterRemix.history_line,
                isFirst: true,
                onTap: () =>
                    _controller.showClearSearchConfirmation(context, settings),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Reset Library Database',
                icon: FlutterRemix.delete_bin_line,
                isLast: true,
                onTap: () => _controller.showResetConfirmation(context, music),
              ),

              const NixBottomSpacer(),
            ],
          ),
        );
      },
    );
  }
}
