import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/settings/artwork_quality.dart';
import 'package:nix/models/settings/timer_gesture.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_slider.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsParams = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

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
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
            onTap: () =>
                settingsParams.setUseAmoledMode(!settingsParams.useAmoledMode),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Accent Color Mode',
            subtitle: settingsParams.accentColorMode.name.toUpperCase(),
            icon: FlutterRemix.palette_line,
            isLast: settingsParams.accentColorMode != AccentColorMode.custom,
            onTap: () => _showAccentModeDialog(context, settingsParams),
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
                    onChanged: (v) => settingsParams.setSplitCdWhenHalfOpen(v),
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
                    onChanged: (v) => settingsParams.setRotateCdWhenPlaying(v),
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
                                onPressed: () {
                                  NixDialog.show(
                                    context: context,
                                    title: 'Reset Speed',
                                    subtitle:
                                        'Reset CD rotation speed to default 20%?',
                                    children: [
                                      CardListTile(
                                        title: 'Reset',
                                        icon: FlutterRemix.check_line,
                                        isFirst: true,
                                        isLast: true,
                                        onTap: () {
                                          settingsParams.setCdRotationSpeed(
                                            20.0,
                                          );
                                          Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          NixSlider(
                            value: settingsParams.cdRotationSpeed,
                            min: 0,
                            max: 100,
                            label: '${settingsParams.cdRotationSpeed.toInt()}%',
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
            onTap: () => _showShapeDialog(context, settingsParams),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Artwork Quality',
            subtitle: settingsParams.artworkQuality.name.toUpperCase(),
            icon: FlutterRemix.image_line,
            onTap: () => _showQualityDialog(context, settingsParams),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Timer Interaction',
            subtitle: settingsParams.timerGesture == TimerGesture.longPress
                ? 'LONG PRESS'
                : 'TAP',
            icon: FlutterRemix.fingerprint_line,
            onTap: () => _showTimerGestureDialog(context, settingsParams),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'SnackBar Position',
            subtitle: settingsParams.snackbarPosition.name.toUpperCase(),
            icon: FlutterRemix.notification_badge_line,
            onTap: () => _showSnackBarPositionDialog(context, settingsParams),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Swipe to Dismiss SnackBar',
            subtitle: 'Gesture dismissal for alerts',
            icon: FlutterRemix.hand_coin_line,
            trailing: Switch(
              value: settingsParams.snackbarSwipeToDismiss,
              onChanged: (v) => settingsParams.setSnackbarSwipeToDismiss(v),
            ),
            onTap: () => settingsParams.setSnackbarSwipeToDismiss(
              !settingsParams.snackbarSwipeToDismiss,
            ),
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
            onTap: () => settingsParams.setShowMiniplayerShadow(
              !settingsParams.showMiniplayerShadow,
            ),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Swipe to Change Track',
            subtitle: 'Swipe artwork left/right to skip',
            icon: FlutterRemix.arrow_left_right_line,
            trailing: Switch(
              value: settingsParams.swipeToChangeTrack,
              onChanged: (v) => settingsParams.setSwipeToChangeTrack(v),
            ),
            onTap: () => settingsParams.setSwipeToChangeTrack(
              !settingsParams.swipeToChangeTrack,
            ),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Track Swipe Action',
            subtitle: settingsParams.trackSwipeAction == TrackSwipeAction.none
                ? 'OFF'
                : 'PLAY / PLAY NEXT',
            icon: FlutterRemix.swap_line,
            onTap: () => _showTrackSwipeActionDialog(context, settingsParams),
            isLast: true,
          ),
          const NixBottomSpacer(),
        ],
      ),
    );
  }

  void _showTrackSwipeActionDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    NixDialog.show(
      context: context,
      title: 'Track Swipe Action',
      children: TrackSwipeAction.values.map((action) {
        final index = TrackSwipeAction.values.indexOf(action);
        String description = '';
        switch (action) {
          case TrackSwipeAction.none:
            description = 'Disable swipe actions on library tracks';
            break;
          case TrackSwipeAction.playPlayback:
            description = 'Swipe to Play (Idle) or Play Next (Playing)';
            break;
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == TrackSwipeAction.values.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: action == TrackSwipeAction.none
                ? 'NONE'
                : 'PLAY / PLAY NEXT',
            subtitle: description,
            onTap: () {
              settings.setTrackSwipeAction(action);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailing: IgnorePointer(
              child: Radio<TrackSwipeAction>(
                value: action,
                groupValue: settings.trackSwipeAction,
                onChanged: (_) {},
              ),
            ),
            isFirst: index == 0,
            isLast: index == TrackSwipeAction.values.length - 1,
          ),
        );
      }).toList(),
    );
  }

  void _showSnackBarPositionDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    NixDialog.show(
      context: context,
      title: 'SnackBar Position',
      children: SnackBarPosition.values.map((position) {
        final index = SnackBarPosition.values.indexOf(position);
        String description = '';
        switch (position) {
          case SnackBarPosition.top:
            description = 'Show alerts at the top of the screen';
            break;
          case SnackBarPosition.bottom:
            description = 'Show alerts at the bottom of the screen';
            break;
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == SnackBarPosition.values.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: position.name.toUpperCase(),
            subtitle: description,
            onTap: () {
              settings.setSnackbarPosition(position);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailing: IgnorePointer(
              child: Radio<SnackBarPosition>(
                value: position,
                groupValue: settings.snackbarPosition,
                onChanged: (_) {},
              ),
            ),
            isFirst: index == 0,
            isLast: index == SnackBarPosition.values.length - 1,
          ),
        );
      }).toList(),
    );
  }

  void _showShapeDialog(BuildContext context, SettingsProvider settings) {
    NixDialog.show(
      context: context,
      title: 'Artwork Shape',
      children: ArtworkShape.values.map((shape) {
        final index = ArtworkShape.values.indexOf(shape);
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == ArtworkShape.values.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: shape.name.toUpperCase(),
            onTap: () {
              settings.setArtworkShape(shape);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailing: IgnorePointer(
              child: Radio<ArtworkShape>(
                value: shape,
                groupValue: settings.artworkShape,
                onChanged: (_) {},
              ),
            ),
            isFirst: index == 0,
            isLast: index == ArtworkShape.values.length - 1,
          ),
        );
      }).toList(),
    );
  }

  void _showQualityDialog(BuildContext context, SettingsProvider settings) {
    final qualities = NixArtworkQuality.values.reversed.toList();
    NixDialog.show(
      context: context,
      title: 'Artwork Quality',
      children: qualities.map((quality) {
        final index = qualities.indexOf(quality);
        String description = '';
        switch (quality) {
          case NixArtworkQuality.high:
            description = 'Full-high quality - Best visuals';
            break;
          case NixArtworkQuality.medium:
            description = 'Balanced quality';
            break;
          case NixArtworkQuality.low:
            description = 'Standard quality - Saves memory';
            break;
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == qualities.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: quality.name.toUpperCase(),
            subtitle: description,
            onTap: () {
              settings.setArtworkQuality(quality);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailing: IgnorePointer(
              child: Radio<NixArtworkQuality>(
                value: quality,
                groupValue: settings.artworkQuality,
                onChanged: (_) {},
              ),
            ),
            isFirst: index == 0,
            isLast: index == qualities.length - 1,
          ),
        );
      }).toList(),
    );
  }

  void _showAccentModeDialog(BuildContext context, SettingsProvider settings) {
    NixDialog.show(
      context: context,
      title: ' Accent Color Mode',
      children: AccentColorMode.values.map((mode) {
        final index = AccentColorMode.values.indexOf(mode);
        String label = mode.name.toUpperCase();
        if (mode == AccentColorMode.dynamic) label = "DYNAMIC (ALBUM ART)";

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == AccentColorMode.values.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: label,
            onTap: () {
              settings.setAccentColorMode(mode);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailing: IgnorePointer(
              child: Radio<AccentColorMode>(
                value: mode,
                groupValue: settings.accentColorMode,
                onChanged: (_) {},
              ),
            ),
            isFirst: index == 0,
            isLast: index == AccentColorMode.values.length - 1,
          ),
        );
      }).toList(),
    );
  }

  void _showTimerGestureDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    NixDialog.show(
      context: context,
      title: 'Timer Interaction',
      children: TimerGesture.values.map((gesture) {
        final index = TimerGesture.values.indexOf(gesture);
        String description = '';
        switch (gesture) {
          case TimerGesture.tap:
            description = 'Single tap to open timer';
            break;
          case TimerGesture.longPress:
            description = 'Long press to avoid accidental touches';
            break;
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == TimerGesture.values.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: gesture.name.toUpperCase(),
            subtitle: description,
            onTap: () {
              settings.setTimerGesture(gesture);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailing: IgnorePointer(
              child: Radio<TimerGesture>(
                value: gesture,
                groupValue: settings.timerGesture,
                onChanged: (_) {},
              ),
            ),
            isFirst: index == 0,
            isLast: index == TimerGesture.values.length - 1,
          ),
        );
      }).toList(),
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
                      settings.customAccentColor.value == color.value;

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
