import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';
import '../../../widgets/list_item/card_list_tile.dart';
import '../../../widgets/common/nix_section_header.dart';

class PlaybackSettingsPage extends StatelessWidget {
  const PlaybackSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Playback'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          const NixSectionHeader(title: 'Playback Behavior', topPadding: 12),
          CardListTile(
            title: 'Auto Play',
            subtitle:
                'Keep playing similar tracks when your current track ends',
            icon: FlutterRemix.play_circle_line,
            trailing: Switch(
              value: settings.autoPlay,
              onChanged: (value) => settings.setAutoPlay(value),
            ),
            isFirst: true,
            onTap: () => settings.setAutoPlay(!settings.autoPlay),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Skip Ending Silence',
            subtitle: 'Automatically trim silent gaps at track ending',
            icon: FlutterRemix.scissors_line,
            trailing: Switch(
              value: settings.skipSilence,
              onChanged: (value) => settings.setSkipSilence(value),
            ),
            onTap: () => settings.setSkipSilence(!settings.skipSilence),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Reset on New Track',
            subtitle: 'Always return to 1.0x when starting a new track',
            icon: FlutterRemix.refresh_line,
            trailing: Switch(
              value: settings.resetSpeedOnNewTrack,
              onChanged: (value) => settings.setResetSpeedOnNewTrack(value),
            ),
            isLast: true,
            onTap: () => settings.setResetSpeedOnNewTrack(
              !settings.resetSpeedOnNewTrack,
            ),
          ),

          const NixSectionHeader(title: 'Player Experience', topPadding: 32),
          CardListTile(
            title: 'Swipe Down to Dismiss',
            subtitle: 'Allow closing the player by swiping down fully',
            icon: FlutterRemix.arrow_down_circle_line,
            trailing: Switch(
              value: settings.swipeToDismiss,
              onChanged: (value) => settings.setSwipeToDismiss(value),
            ),
            isFirst: true,
            onTap: () => settings.setSwipeToDismiss(!settings.swipeToDismiss),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Haptic Feedback',
            subtitle: 'Vibrate during navigation and playback control',
            icon: FlutterRemix.smartphone_line,
            trailing: Switch(
              value: settings.enableHaptics,
              onChanged: (value) => settings.setEnableHaptics(value),
            ),
            isLast: true,
            onTap: () => settings.setEnableHaptics(!settings.enableHaptics),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 12, top: 24, right: 12),
            child: Text(
              'Gestures allow for a more intuitive control of your music. Auto Play ensures your music experience is seamless and continuous.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
