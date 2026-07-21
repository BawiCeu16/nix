import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_slider.dart';
import 'package:nix/ui/screens/settings/controllers/appearance_settings_controller.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  late final AppearanceSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppearanceSettingsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsParams = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainer,
          appBar: AppBar(
            title: const Text('Appearance'),
            centerTitle: true,
            scrolledUnderElevation: 0,
            backgroundColor: colorScheme.surfaceContainer,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            physics: const BouncingScrollPhysics(),
            children: [
              const NixSectionHeader(title: 'Theme & Colors', topPadding: 16),
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  child: M3EToggleButtonGroup(
                    type: M3EButtonGroupType.connected,
                    selectedIndex: settingsParams.themeMode.index,
                    onSelectedIndexChanged: (index) {
                      if (index != null) {
                        settingsParams.setThemeMode(ThemeMode.values[index]);
                      }
                    },
                    actions: const [
                      M3EToggleButtonGroupAction(
                        label: Text('SYSTEM'),
                        icon: Icon(FlutterRemix.smartphone_line),
                      ),
                      M3EToggleButtonGroupAction(
                        label: Text('LIGHT'),
                        icon: Icon(FlutterRemix.sun_line),
                      ),
                      M3EToggleButtonGroupAction(
                        label: Text('DARK'),
                        icon: Icon(FlutterRemix.moon_line),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'AMOLED Mode',
                subtitle: 'Pure black for OLED screens',
                icon: FlutterRemix.moon_clear_line,
                trailing: Switch(
                  value: settingsParams.useAmoledMode,
                  onChanged: (v) => settingsParams.setUseAmoledMode(v),
                ),
                onTap: () => settingsParams.setUseAmoledMode(
                  !settingsParams.useAmoledMode,
                ),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Accent Color Mode',
                subtitle: settingsParams.accentColorMode.name.toUpperCase(),
                icon: FlutterRemix.palette_line,
                isLast: settingsParams.accentColorMode != AccentColorMode.custom,
                onTap: () =>
                    _controller.showAccentModeDialog(context, settingsParams),
              ),
              if (settingsParams.accentColorMode == AccentColorMode.custom) ...[
                const SizedBox(height: 2.5),
                _CustomColorPicker(settings: settingsParams),
              ],
              const NixSectionHeader(title: 'Artwork & Visuals', topPadding: 24),
              NixCardExpansionTile(
                title: 'Y2k(cd) style album art',
                icon: FlutterRemix.album_line,
                isFirst: true,
                showExpansionIcon: settingsParams.useCdArtworkStyle,
                initiallyExpanded: settingsParams.useCdArtworkStyle,
                trailing: Switch(
                  value: settingsParams.useCdArtworkStyle,
                  onChanged: (v) => settingsParams.setUseCdArtworkStyle(v),
                ),
                children: [
                  if (settingsParams.useCdArtworkStyle) ...[
                    const SizedBox(height: 2.5),
                    CardListTile(
                      title: 'Split CD Horizontally',
                      icon: FlutterRemix.split_cells_horizontal,
                      trailing: Switch(
                        value: settingsParams.splitCdWhenHalfOpen,
                        onChanged: (v) =>
                            settingsParams.setSplitCdWhenHalfOpen(v),
                      ),
                      onTap: () => settingsParams.setSplitCdWhenHalfOpen(
                        !settingsParams.splitCdWhenHalfOpen,
                      ),
                    ),
                    const SizedBox(height: 2.5),
                    CardListTile(
                      title: 'Revolving CD Disc',
                      icon: FlutterRemix.disc_line,
                      trailing: Switch(
                        value: settingsParams.rotateCdWhenPlaying,
                        onChanged: (v) =>
                            settingsParams.setRotateCdWhenPlaying(v),
                      ),
                      onTap: () => settingsParams.setRotateCdWhenPlaying(
                        !settingsParams.rotateCdWhenPlaying,
                      ),
                    ),
                    if (settingsParams.rotateCdWhenPlaying) ...[
                      const SizedBox(height: 2.5),
                      Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                            bottomRight: Radius.circular(5),
                          ),
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Rotation Speed',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      FlutterRemix.refresh_line,
                                      size: 18,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Reset to default',
                                    onPressed: () => _controller.showResetCdSpeedDialog(
                                      context,
                                      settingsParams,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              NixSlider(
                                value: settingsParams.cdRotationSpeed,
                                min: 0,
                                max: 100,
                                label:
                                    '${settingsParams.cdRotationSpeed.toInt()}%',
                                onChanged: (v) =>
                                    settingsParams.setCdRotationSpeed(v),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Artwork Shape(Default)',
                subtitle: settingsParams.artworkShape.name.toUpperCase(),
                icon: FlutterRemix.shape_2_line,
                onTap: () =>
                    _controller.showShapeDialog(context, settingsParams),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Artwork Quality',
                subtitle: settingsParams.artworkQuality.name.toUpperCase(),
                icon: FlutterRemix.image_line,
                onTap: () =>
                    _controller.showQualityDialog(context, settingsParams),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Miniplayer Shadow',
                subtitle: 'Dynamic depth effect for player',
                icon: FlutterRemix.magic_line,
                trailing: Switch(
                  value: settingsParams.showMiniplayerShadow,
                  onChanged: (v) => settingsParams.setShowMiniplayerShadow(v),
                ),
                isLast: true,
                onTap: () => settingsParams.setShowMiniplayerShadow(
                  !settingsParams.showMiniplayerShadow,
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

class _CustomColorPicker extends StatelessWidget {
  final SettingsProvider settings;
  const _CustomColorPicker({required this.settings});

  static const List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
          top: Radius.circular(5),
        ),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 12),
              child: Text(
                'Pick Accent Color',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  final isSelected =
                      settings.customAccentColor.toARGB32() == color.toARGB32();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => settings.setCustomAccentColor(color),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: colorScheme.primary, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                FlutterRemix.check_line,
                                color: colorScheme.onPrimary,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
