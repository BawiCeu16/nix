import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/models/music/song.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/common/nix_action_row.dart';
import 'package:nix/ui/widgets/common/nix_page_header.dart';
import 'package:nix/core/artwork_helper.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';

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
            icon: const Icon(FlutterRemix.add_line),
            onPressed: () => PlaylistDialogs.showPlaylistActionDialog(context),
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, music, child) {
          Playlist? pl;
          bool isSystemPlaylist = false;

          // Resolve playlist (User or System)
          if (playlistName == "Recently Listened" || playlistId == "recently_played") {
            pl = music.recentlyPlayed;
            isSystemPlaylist = true;
          } else if (playlistName == "Favorites" || playlistId == "favorites") {
            pl = music.favorites;
            isSystemPlaylist = true;
          } else if (playlistName == "Top Listened" || playlistId == "top_played") {
            pl = music.topPlayed;
            isSystemPlaylist = true;
          } else {
            pl = music.playlists.where((p) => p.name == playlistName || p.id == playlistId).firstOrNull;
          }

          final songs = List<Song>.from(pl?.songs ?? []);
          final artwork = ArtworkHelper.getFirstArtwork(songs.map((s) => s.uri).toList());

          if (songs.isEmpty) {
            return NixEmptyState(
              icon: FlutterRemix.music_2_line,
              title: "No tracks here yet",
            );
          }

          return ReorderableListView.builder(
            buildDefaultDragHandles: !isSystemPlaylist,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: songs.length + 2, // Header + Songs + Bottom Padding
            onReorder: (oldIndex, newIndex) {
              if (isSystemPlaylist) return;
              // Adjust for header at index 0
              if (oldIndex < 1 || oldIndex > songs.length) return;
              
              int adjustedOld = oldIndex - 1;
              int adjustedNew = newIndex - 1;
              
              if (adjustedNew < 0) adjustedNew = 0;
              if (adjustedNew >= songs.length) adjustedNew = songs.length - 1;

              music.reorderPlaylistSongs(pl!.id, adjustedOld, adjustedNew + (oldIndex < newIndex ? 1 : 0));
            },
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.transparent,
              child: child,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return NixPageHeader(
                  key: const ValueKey('header'),
                  title: playlistName,
                  subtitle: "${songs.length} Tracks",
                  artwork: artwork,
                  actionRow: NixActionRow(
                    onShuffle: () {
                      final audio = context.read<CurrentMusicProvider>();
                      final shuffled = List<Song>.from(songs)..shuffle();
                      if (!audio.isShuffleEnabled) audio.toggleShuffle();
                      audio.playSong(shuffled.first, playlist: pl);
                    },
                    onPlay: () {
                      context.read<CurrentMusicProvider>().playSong(songs.first, playlist: pl);
                    },
                  ),
                );
              }

              if (index == songs.length + 1) {
                return const SizedBox(key: ValueKey('padding'), height: 120);
              }

              final songIndex = index - 1;
              final song = songs[songIndex];

              Widget tile = TrackTile(
                track: song,
                playlistContext: songs,
                isFirst: songIndex == 0,
                isLast: songIndex == songs.length - 1,
              );

              // Add swipe-to-remove for user playlists
              if (!isSystemPlaylist) {
                return Dismissible(
                  key: ValueKey('${pl!.id}_${song.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.only(right: 24),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(FlutterRemix.delete_bin_line, color: colorScheme.onErrorContainer),
                  ),
                  onDismissed: (_) {
                    music.removeSongFromPlaylist(pl!.id, song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed "${song.title}"'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: tile,
                );
              }

              return Container(
                key: ValueKey('song_${song.id}'),
                child: tile,
              );
            },
          );
        },
      ),
    );
  }
}
