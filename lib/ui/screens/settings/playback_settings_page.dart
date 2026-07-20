import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_slider.dart';

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
            onTap: () => settings.setResetSpeedOnNewTrack(
              !settings.resetSpeedOnNewTrack,
            ),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Remember Playback Position',
            subtitle: 'Resume tracks from where you last left off',
            icon: FlutterRemix.time_line,
            trailing: Switch(
              value: settings.resumeFromPlayedDuration,
              onChanged: (value) => settings.setResumeFromPlayedDuration(value),
            ),
            isLast: true,
            onTap: () => settings.setResumeFromPlayedDuration(
              !settings.resumeFromPlayedDuration,
            ),
          ),

          const NixSectionHeader(title: 'Player Experience', topPadding: 32),
          NixCardExpansionTile(
            title: 'Up Next Indicator',
            subtitle: 'Show the upcoming track before the current one ends',
            icon: FlutterRemix.skip_forward_mini_line,
            isFirst: true,
            initiallyExpanded: settings.upNextIndicator,
            showExpansionIcon: settings.upNextIndicator,
            trailing: Switch(
              value: settings.upNextIndicator,
              onChanged: (value) => settings.setUpNextIndicator(value),
            ),
            children: [
              if (settings.upNextIndicator) ...[
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
                              'UPNext Show Time',
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
                              onPressed: () =>
                                  settings.setUpNextIndicatorTime(20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        NixSlider(
                          value: settings.upNextIndicatorTime.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          label: '${settings.upNextIndicatorTime}s',
                          onChanged: (val) =>
                              settings.setUpNextIndicatorTime(val.toInt()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Save Lyrics Offline',
            subtitle: 'Store fetched lyrics locally for offline playback',
            icon: FlutterRemix.download_cloud_2_line,
            trailing: Switch(
              value: settings.saveLyricsOffline,
              onChanged: (value) => settings.setSaveLyricsOffline(value),
            ),
            isLast: true,
            onTap: () =>
                settings.setSaveLyricsOffline(!settings.saveLyricsOffline),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 12, top: 24, right: 12),
            child: Text(
              'Gestures allow for a more intuitive control of your music. Auto Play ensures your music experience is seamless and continuous.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const NixBottomSpacer(),
        ],
      ),
    );
  }
}
