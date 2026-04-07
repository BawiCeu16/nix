import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'nix_dialog.dart';
import '../common/nix_slider.dart';
import '../list_item/card_list_tile.dart';
import '../buttons/expressive_tone_button.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/current_music_provider.dart';
import '../../../providers/sleep_timer_provider.dart';
import 'sleep_timer_dialog.dart';
import '../../../core/format.dart';

class PlaybackSpeedDialog extends StatelessWidget {
  const PlaybackSpeedDialog({super.key});

  static void show(BuildContext context) {
    NixDialog.show(
      context: context,
      title: "Playback Speed",
      subtitle: "Fine-tune your listening tempo",
      children: [const PlaybackSpeedDialog()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final music = context.watch<CurrentMusicProvider>();
    final timer = context.watch<SleepTimerProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Playback Speed Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Playback Speed (${settings.playbackSpeed.toStringAsFixed(1)}x)",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        NixSlider(
          value: settings.playbackSpeed,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          label: '${settings.playbackSpeed.toStringAsFixed(1)}x',
          onChanged: (v) {
            settings.setPlaybackSpeed(v);
            music.setSpeed(v);
          },
        ),
        const SizedBox(height: 16),

        // Settings Toggles
        CardListTile(
          title: "Reset on New Track",
          subtitle: "Always return to 1.0x for next song",
          icon: FlutterRemix.refresh_line,
          trailing: Switch(
            value: settings.resetSpeedOnNewTrack,
            onChanged: (v) => settings.setResetSpeedOnNewTrack(v),
          ),
          isFirst: true,
          isLast: true,
          onTap: () =>
              settings.setResetSpeedOnNewTrack(!settings.resetSpeedOnNewTrack),
        ),

        const SizedBox(height: 24),
        ExpressiveToneButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Done"),
        ),
      ],
    );
  }
}
