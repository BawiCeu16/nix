import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/common/nix_action_row.dart';
import 'package:nix/ui/widgets/common/nix_page_header.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import '../../../../services/snackbar_service.dart';

import 'package:nix/ui/widgets/common/nix_playlist_cover.dart';

class PlaylistViewPage extends StatelessWidget {
  final String playlistName;
  final String? playlistId;

  const PlaylistViewPage({
    super.key,
    this.playlistName = "Unknown Playlist",
    this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: Text(playlistName),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(FlutterRemix.edit_line),
            onPressed: () => PlaylistDialogs.showPlaylistActionDialog(
              context,
              initialName: playlistName,
              playlistId: playlistId,
            ),
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, music, child) {
          Playlist? pl;
          bool isSystemPlaylist = false;

          // Resolve playlist (User or System)
          if (playlistId == "recently_played" ||
              playlistName == "Recently Listened") {
            pl = music.recentlyPlayed;
            isSystemPlaylist = true;
          } else if (playlistId == "favorites" || playlistName == "Favorites") {
            pl = music.favorites;
            isSystemPlaylist = true;
          } else if (playlistId == "top_played" ||
              playlistName == "Top Listened") {
            pl = music.topPlayed;
            isSystemPlaylist = true;
          } else {
            // Find by ID first, then name
            pl = music.playlists.firstWhere(
              (p) => p.id == playlistId || p.name == playlistName,
              orElse: () => music.playlists.first,
            );
          }

          final tracks = List<Track>.from(pl.tracks);

          if (tracks.isEmpty && isSystemPlaylist) {
            return NixEmptyState(
              icon: FlutterRemix.music_2_line,
              title: "No tracks here yet",
            );
          }

          return ReorderableListView.builder(
            buildDefaultDragHandles: !isSystemPlaylist,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: tracks.length + 2, // Header + Tracks + Bottom Padding
            onReorder: (oldIndex, newIndex) {
              if (isSystemPlaylist) return;
              if (oldIndex < 1 || oldIndex > tracks.length) return;

              int adjustedOld = oldIndex - 1;
              int adjustedNew = newIndex - 1;

              if (adjustedNew < 0) adjustedNew = 0;
              if (adjustedNew >= tracks.length) adjustedNew = tracks.length - 1;

              music.reorderPlaylistTracks(pl!.id, adjustedOld, adjustedNew);
            },
            proxyDecorator: (child, index, animation) =>
                Material(color: Colors.transparent, child: child),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  key: const ValueKey('header'),
                  children: [
                    NixPageHeader(
                      title: pl!.name,
                      subtitle: "${tracks.length} Tracks",
                      customArtwork: NixPlaylistCover(
                        playlist: pl,
                        size: 300,
                        radius: 24,
                      ),
                      actionRow: NixActionRow(
                        onShuffle: () {
                          final audio = context.read<CurrentMusicProvider>();
                          final shuffled = List<Track>.from(tracks)..shuffle();
                          if (!audio.isShuffleEnabled) audio.toggleShuffle();
                          audio.playTrack(shuffled.first, playlist: pl);
                        },
                        onPlay: () {
                          context.read<CurrentMusicProvider>().playTrack(
                            tracks.first,
                            playlist: pl,
                          );
                        },
                      ),
                    ),
                  ],
                );
              }

              if (index == tracks.length + 1) {
                return const NixBottomSpacer(key: ValueKey('padding'));
              }

              final trackIndex = index - 1;
              final track = tracks[trackIndex];

              Widget tile = TrackTile(
                track: track,
                playlistContext: tracks,
                isFirst: trackIndex == 0,
                isLast: trackIndex == tracks.length - 1,
              );

              // Add swipe-to-remove for user playlists
              if (!isSystemPlaylist) {
                return Dismissible(
                  key: ValueKey('${pl!.id}_${track.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.only(right: 24),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FlutterRemix.delete_bin_line,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) {
                    music.removeTrackFromPlaylist(pl!.id, track);
                    context.showSuccessSnackBar('Removed "${track.title}"');
                  },
                  child: tile,
                );
              }

              return Container(key: ValueKey('track_${track.id}'), child: tile);
            },
          );
        },
      ),
    );
  }
}
