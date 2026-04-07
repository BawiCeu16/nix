import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_provider.dart';
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
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          const NixSectionHeader(title: 'General', topPadding: 12),
          CardListTile(
            title: 'Auto Play',
            subtitle: 'Keep playing similar tracks when your current song ends',
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
            title: 'Swipe Down to Dismiss',
            subtitle: 'Allow closing the player by swiping down fully',
            icon: FlutterRemix.arrow_down_circle_line,
            trailing: Switch(
              value: settings.swipeToDismiss,
              onChanged: (value) => settings.setSwipeToDismiss(value),
            ),
            isLast: true,
            onTap: () => settings.setSwipeToDismiss(!settings.swipeToDismiss),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 12, top: 24, right: 12),
            child: Text(
              'Gestures allow for a more intuitive control of your music. Auto Play ensures your music никогда doesn\'t stop.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
