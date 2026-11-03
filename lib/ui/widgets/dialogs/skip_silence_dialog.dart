import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/providers/settings_provider.dart';

class SkipSilenceDialog extends StatelessWidget {
  const SkipSilenceDialog({super.key});

  static void show(BuildContext context) {
    NixDialog.show(
      context: context,
      title: "Skip Silence",
      children: [const SkipSilenceDialog()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardListTile(
          title: "Trim Silent Gaps",
          icon: FlutterRemix.scissors_line,
          trailing: Switch(
            value: settings.skipSilence,
            onChanged: (v) => settings.setSkipSilence(v),
          ),
          isFirst: true,
          isLast: true,
          onTap: () => settings.setSkipSilence(!settings.skipSilence),
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
