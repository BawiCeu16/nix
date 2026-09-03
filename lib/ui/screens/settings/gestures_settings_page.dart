import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/settings/timer_gesture.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/screens/settings/controllers/gestures_settings_controller.dart';

class GesturesSettingsPage extends StatefulWidget {
  const GesturesSettingsPage({super.key});

  @override
  State<GesturesSettingsPage> createState() => _GesturesSettingsPageState();
}

class _GesturesSettingsPageState extends State<GesturesSettingsPage> {
  late final GesturesSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GesturesSettingsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainer,
          appBar: AppBar(
            title: const Text('Gestures & Interface'),
            centerTitle: true,
            scrolledUnderElevation: 0,
            backgroundColor: colorScheme.surfaceContainer,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            physics: const BouncingScrollPhysics(),
            children: [
              const NixSectionHeader(title: 'Gestures', topPadding: 16),
              CardListTile(
                title: 'Swipe Down to Dismiss',
                subtitle: 'Allow closing the player by swiping down fully',
                icon: FlutterRemix.arrow_down_circle_line,
                trailing: Switch(
                  value: settings.swipeToDismiss,
                  onChanged: (value) => settings.setSwipeToDismiss(value),
                ),
                isFirst: true,
                onTap: () =>
                    settings.setSwipeToDismiss(!settings.swipeToDismiss),
              ),
              const SizedBox(height: 2.5),
              NixCardExpansionTile(
                title: 'Swipe to Change Track',
                subtitle: 'Swipe artwork left/right to skip',
                icon: FlutterRemix.arrow_left_right_line,
                showExpansionIcon: settings.swipeToChangeTrack,
                initiallyExpanded: false,
                trailing: Switch(
                  value: settings.swipeToChangeTrack,
                  onChanged: (v) => settings.setSwipeToChangeTrack(v),
                ),
                children: [
                  if (settings.swipeToChangeTrack) ...[
                    const SizedBox(height: 2.5),
                    CardListTile(
                      title: 'Fast Swipe Artwork',
                      subtitle:
                          'Requires only a small swipe distance to skip tracks',
                      icon: FlutterRemix.speed_line,
                      trailing: Switch(
                        value: settings.fastSwipeArtwork,
                        onChanged: (v) => settings.setFastSwipeArtwork(v),
                      ),
                      onTap: () => settings.setFastSwipeArtwork(
                        !settings.fastSwipeArtwork,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Track Swipe Action',
                subtitle: settings.trackSwipeAction == TrackSwipeAction.none
                    ? 'OFF'
                    : 'PLAY / PLAY NEXT',
                icon: FlutterRemix.swap_line,
                onTap: () =>
                    _controller.showTrackSwipeActionDialog(context, settings),
                isLast: true,
              ),
              const NixSectionHeader(title: 'Haptic Feedback', topPadding: 24),
              NixCardExpansionTile(
                title: 'Haptic Feedback',
                subtitle: 'Vibrate during navigation and playback control',
                icon: FlutterRemix.smartphone_line,
                isFirst: true,
                isLast: true,
                initiallyExpanded: false,
                showExpansionIcon: settings.enableHaptics,
                trailing: Switch(
                  value: settings.enableHaptics,
                  onChanged: (value) => settings.setEnableHaptics(value),
                ),
                children: [
                  if (settings.enableHaptics) ...[
                    const SizedBox(height: 2.5),
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
                        ),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Intensity',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: HapticForce.values.map((force) {
                                final isSelected =
                                    settings.hapticForce == force;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: InkWell(
                                      onTap: () =>
                                          settings.setHapticForce(force),
                                      borderRadius: BorderRadius.circular(100),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.outlineVariant,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            force.name.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const NixSectionHeader(
                title: 'Interface & Alerts',
                topPadding: 24,
              ),
              CardListTile(
                title: 'Timer Interaction',
                subtitle: settings.timerGesture == TimerGesture.longPress
                    ? 'LONG PRESS'
                    : 'TAP',
                icon: FlutterRemix.fingerprint_line,
                isFirst: true,
                onTap: () =>
                    _controller.showTimerGestureDialog(context, settings),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'SnackBar Position',
                subtitle: settings.snackbarPosition.name.toUpperCase(),
                icon: FlutterRemix.notification_badge_line,
                onTap: () =>
                    _controller.showSnackBarPositionDialog(context, settings),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Swipe to Dismiss SnackBar',
                subtitle: 'Gesture dismissal for alerts',
                icon: FlutterRemix.hand_coin_line,
                trailing: Switch(
                  value: settings.snackbarSwipeToDismiss,
                  onChanged: (v) => settings.setSnackbarSwipeToDismiss(v),
                ),
                onTap: () => settings.setSnackbarSwipeToDismiss(
                  !settings.snackbarSwipeToDismiss,
                ),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Auto Scroll Queue',
                subtitle:
                    'Automatically scroll to now playing when queue is opened',
                icon: FlutterRemix.play_list_2_line,
                trailing: Switch(
                  value: settings.autoScrollQueue,
                  onChanged: (value) => settings.setAutoScrollQueue(value),
                ),
                isLast: true,
                onTap: () =>
                    settings.setAutoScrollQueue(!settings.autoScrollQueue),
              ),
              const NixBottomSpacer(),
            ],
          ),
        );
      },
    );
  }
}
