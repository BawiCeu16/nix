import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../widgets/list_item/card_list_tile.dart';

class PlaybackSettingsPage extends StatelessWidget {
  const PlaybackSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsParams = context.watch<SettingsProvider>();
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
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 12, bottom: 8),
            child: Text(
              'GENERAL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          CardListTile(
            title: 'Auto Play',
            subtitle: 'Start next song automatically when current song ends',
            icon: FlutterRemix.play_circle_line,
            trailing: Switch(
              value: settingsParams.autoPlay,
              onChanged: (val) => settingsParams.autoPlay = val,
            ),
            isFirst: true,
            onTap: () => settingsParams.autoPlay = !settingsParams.autoPlay,
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Swipe to Dismiss',
            subtitle: 'Swipe down on miniplayer to stop playback',
            icon: FlutterRemix.arrow_down_circle_line,
            trailing: Switch(
              value: settingsParams.swipeToDismiss,
              onChanged: (val) => settingsParams.swipeToDismiss = val,
            ),
            isLast: true,
            onTap: () =>
                settingsParams.swipeToDismiss = !settingsParams.swipeToDismiss,
          ),

          const Padding(
            padding: EdgeInsets.only(left: 12, top: 24, right: 12),
            child: Text(
              'Gestures allow for a more intuitive control of your music. Auto Play ensures your music никогда doesn\'t stop.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
