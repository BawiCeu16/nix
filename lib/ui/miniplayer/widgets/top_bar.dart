import 'package:flutter/material.dart';
import 'package:nix/providers/sleep_timer_provider.dart';
import 'package:nix/ui/widgets/dialogs/sleep_timer_dialog.dart';
import 'package:provider/provider.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';
import 'package:nix/ui/widgets/dialogs/track_info_dialog.dart';
import 'package:nix/core/format.dart';
import 'package:nix/ui/widgets/dialogs/playback_speed_dialog.dart';
import 'package:nix/ui/widgets/dialogs/skip_silence_dialog.dart';

class TopBar extends StatelessWidget {
  final double topRowOpacity;
  final double bounceProgressValue;
  final Color onSecondary;
  final VoidCallback onSnapToMini;

  const TopBar({
    super.key,
    required this.topRowOpacity,
    required this.bounceProgressValue,
    required this.onSecondary,
    required this.onSnapToMini,
  });

  @override
  Widget build(BuildContext context) {
    final currentMusic = context.watch<CurrentMusicProvider>();
    final playlistName = currentMusic.currentTrack?.album ?? '';

    return Material(
      type: MaterialType.transparency,
      child: Opacity(
        opacity: topRowOpacity,
        child: Transform.translate(
          offset: Offset(0, (1 - bounceProgressValue) * -100),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: onSnapToMini,
                    icon: Icon(
                      FlutterRemix.arrow_down_s_line,
                      color: onSecondary,
                    ),
                    iconSize: 26.0,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Playing from",
                          style: TextStyle(
                            color: onSecondary.withValues(alpha: .8),
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          playlistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20.0,
                            color: onSecondary.withValues(alpha: .9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    onPressed: () {
                      final track = currentMusic.currentTrack;
                      if (track == null) return;

                      final music = context.read<MusicProvider>();
                      final isFav = music.isFavorite(track);

                      NixDialog.show(
                        context: context,
                        title: track.title,
                        subtitle: track.artist,
                        trackId: track.id,
                        children: [
                          CardListTile(
                            title: isFav
                                ? "Remove from Favorites"
                                : "Add to Favorites",
                            icon: isFav
                                ? FlutterRemix.heart_3_fill
                                : FlutterRemix.heart_3_line,
                            isFirst: true,
                            onTap: () {
                              music.toggleFavorite(track);
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                          ),
                          const SizedBox(height: 2.5),
                          CardListTile(
                            title: "Add to Playlist",
                            icon: FlutterRemix.add_box_line,
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).pop();
                              PlaylistDialogs.showPlaylistPicker(
                                context,
                                track,
                              );
                            },
                          ),
                          const SizedBox(height: 2.5),
                          CardListTile(
                            title: "Playback Speed",
                            icon: FlutterRemix.speed_line,
                            onTap: () {
                              Navigator.pop(context);
                              PlaybackSpeedDialog.show(context);
                            },
                          ),
                          const SizedBox(height: 2.5),
                          CardListTile(
                            title: "Skip Silence",
                            icon: FlutterRemix.scissors_cut_line,
                            onTap: () {
                              Navigator.pop(context);
                              SkipSilenceDialog.show(context);
                            },
                          ),
                          const SizedBox(height: 2.5),
                          CardListTile(
                            title:
                                "Sleep Timer${context.read<SleepTimerProvider>().isActive ? ' (${context.read<SleepTimerProvider>().remainingTime?.shortFormat()})' : ''}",
                            icon: FlutterRemix.timer_line,
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).pop();
                              SleepTimerDialog.show(context);
                            },
                          ),
                          const SizedBox(height: 2.5),
                          CardListTile(
                            title: "Track Info",
                            icon: FlutterRemix.information_line,
                            isLast: true,
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).pop();
                              TrackInfoDialog.show(
                                context,
                                title: track.title,
                                artist: track.artist,
                                album: track.album,
                                duration: Duration(
                                  milliseconds: track.duration,
                                ).shortFormat(),
                                size: track.size.formatBytes(),
                                filePath: track.uri,
                                trackId: track.id,
                              );
                            },
                          ),
                        ],
                      );
                    },
                    icon: Icon(FlutterRemix.more_fill, color: onSecondary),
                    iconSize: 26.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
