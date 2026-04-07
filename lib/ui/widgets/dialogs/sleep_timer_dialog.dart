import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:provider/provider.dart';
import '../../../providers/sleep_timer_provider.dart';
import '../../../providers/current_music_provider.dart';
import '../buttons/expressive_button.dart';
import 'nix_dialog.dart';
import '../../../core/format.dart';
import '../common/nix_slider.dart';

class SleepTimerDialog extends StatefulWidget {
  const SleepTimerDialog({super.key});

  static void show(BuildContext context) {
    NixDialog.show(
      context: context,
      title: "Sleep Timer",
      subtitle: "Stop playback after a set time",
      children: [const SleepTimerDialog()],
    );
  }

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  double _customMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<SleepTimerProvider>();
    final musicProvider = context.read<CurrentMusicProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (timerProvider.isActive) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Icon(FlutterRemix.timer_2_line, size: 48, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text("Timer Active", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            timerProvider.remainingTime?.shortFormat() ?? "00:00",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ExpressiveButton(
                  onPressed: () {
                    timerProvider.cancel();
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel Timer"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ExpressiveToneButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        _buildPresets(timerProvider, musicProvider),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "Custom Duration",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        NixSlider(
          value: _customMinutes,
          min: 1,
          max: 120,
          divisions: 119,
          label: _formatDuration(_customMinutes),
          onChanged: (v) => setState(() => _customMinutes = v),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: ExpressiveButton(
                onPressed: () {
                  timerProvider.setTimer(
                    Duration(minutes: _customMinutes.round()),
                    musicProvider,
                  );
                  Navigator.pop(context);
                },
                child: const Text("Set Timer"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ExpressiveToneButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(double minutes) {
    final int m = minutes.round();
    if (m >= 60) {
      final int h = m ~/ 60;
      final int remainingM = m % 60;
      return remainingM > 0 ? '${h}h ${remainingM}m' : '${h}h';
    }
    return '${m}m';
  }

  Widget _buildPresets(SleepTimerProvider timer, CurrentMusicProvider music) {
    final presets = [15, 20, 30, 60, 120];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: presets.map((m) {
        return InkWell(
          onTap: () {
            timer.setTimer(Duration(minutes: m), music);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              m >= 60 ? "${m ~/ 60}h" : "${m}m",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
