import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';
import 'package:nix/ui/widgets/dialogs/song_info_dialog.dart';
import 'package:nix/ui/widgets/dialogs/sleep_timer_dialog.dart';
import 'package:nix/providers/sleep_timer_provider.dart';
import 'package:nix/core/format.dart';

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
    final playlistName = currentMusic.currentSong?.album ?? '';

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
                    onPressed: () {
                      final song = currentMusic.currentSong;
                      if (song == null) return;

                      final music = context.read<MusicProvider>();
                      final isFav = music.isFavorite(song);

                      NixDialog.show(
                        context: context,
                        title: song.title,
                        subtitle: song.artist,
                        songId: song.id,
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
                              music.toggleFavorite(song);
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                          ),
                          const SizedBox(height: 2.5),
                          CardListTile(
                            title: "Add to Playlist",
                            icon: FlutterRemix.add_box_line,
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).pop();
                              PlaylistDialogs.showPlaylistPicker(context, song);
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
                            title: "Song Info",
                            icon: FlutterRemix.information_line,
                            isLast: true,
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).pop();
                              SongInfoDialog.show(
                                context,
                                title: song.title,
                                artist: song.artist,
                                album: song.album,
                                duration: Duration(
                                  milliseconds: song.duration,
                                ).shortFormat(),
                                size: song.size.formatBytes(),
                                filePath: song.uri,
                                songId: song.id,
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
