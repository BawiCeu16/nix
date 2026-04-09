import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'nix_dialog.dart';
import '../list_item/card_list_tile.dart';
import '../buttons/expressive_tone_button.dart';
import 'package:nix/providers/settings_provider.dart';

class SkipSilenceDialog extends StatelessWidget {
  const SkipSilenceDialog({super.key});

  static void show(BuildContext context) {
    NixDialog.show(
      context: context,
      title: "Skip Silence",
      subtitle: "Optimize your transitions",
      children: [const SkipSilenceDialog()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardListTile(
          title: "Trim Silent Gaps",
          subtitle: "Automatically skip silence at the end of tracks",
          icon: FlutterRemix.scissors_line,
          trailing: Switch(
            value: settings.skipSilence,
            onChanged: (v) => settings.setSkipSilence(v),
          ),
          isFirst: true,
          isLast: true,
          onTap: () => settings.setSkipSilence(!settings.skipSilence),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "When enabled, we'll automatically skip transitions if the last few seconds of a song are silent air.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
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
