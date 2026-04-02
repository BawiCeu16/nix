import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/buttons/expressive_button.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';

class NixActionRow extends StatelessWidget {
  final VoidCallback onShuffle;
  final VoidCallback onPlay;
  final String playLabel;

  const NixActionRow({
    super.key,
    required this.onShuffle,
    required this.onPlay,
    this.playLabel = "Play All",
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ExpressiveToneButton(
            onPressed: onShuffle,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FlutterRemix.shuffle_fill, size: 20),
                SizedBox(width: 8),
                Text("Shuffle"),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ExpressiveButton(
            onPressed: onPlay,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FlutterRemix.play_fill, size: 20),
                const SizedBox(width: 8),
                Text(playLabel),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
