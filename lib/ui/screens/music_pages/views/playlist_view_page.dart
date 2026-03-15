import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';

class PlaylistViewPage extends StatelessWidget {
  final String playlistName;

  const PlaylistViewPage({super.key, this.playlistName = "Unknown Playlist"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: Text(playlistName),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FlutterRemix.play_fill),
            onPressed: () {
              final music = context.read<MusicProvider>();
              final pl = music.playlists.where((p) => p.name == playlistName).firstOrNull;
              if (pl != null && pl.songs.isNotEmpty) {
                context.read<CurrentMusicProvider>().playSong(pl.songs.first, playlist: pl);
              }
            },
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, music, child) {
          final pl = music.playlists.where((p) => p.name == playlistName).firstOrNull;
          final songs = pl?.songs ?? [];

          if (songs.isEmpty) {
            return const Center(child: Text("No tracks in this playlist."));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return TrackTile(
                  track: songs[index],
                  playlistContext: songs,
                  isFirst: index == 0,
                  isLast: index == songs.length - 1,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
