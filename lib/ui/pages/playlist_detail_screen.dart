import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/%20utils/translator.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/song_details_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistName;

  const PlaylistDetailScreen({super.key, required this.playlistName});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final songIds = musicProvider.playlists[playlistName] ?? [];
    final songs = musicProvider.songs
        .where((song) => songIds.contains(song.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(playlistName)),
      body: songs.isEmpty
          ? const Center(child: Text('No songs in this playlist.'))
          : LiveList.options(
              options: const LiveOptions(
                delay: Duration(milliseconds: 50),
                showItemInterval: Duration(milliseconds: 80),
                showItemDuration: Duration(milliseconds: 350),
              ),
              itemCount: songs.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index, animation) {
                final song = songs[index];
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1), // Slide from bottom
                      end: Offset.zero,
                    ).animate(animation),
                    child: ListTile(
                      leading: QueryArtworkWidget(
                        artworkBorder: BorderRadius.circular(10),
                        id: song.id,
                        keepOldArtwork: true,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: const Icon(Icons.music_note),
                      ),
                      title: Text(song.title, overflow: TextOverflow.ellipsis),
                      subtitle: Text(song.artist ?? 'Unknown Artist'),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () =>
                            _showSongOptions(context, playlistName, song),
                      ),
                      onTap: () => musicProvider.playSong(song),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddSongDialog(context),
      ),
    );
  }

  void _showAddSongDialog(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();
    final allSongs = musicProvider.songs;
    final height = MediaQuery.of(context).size.height / 2.5;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Song'),
        content: SizedBox(
          width: double.maxFinite,
          height: height,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: allSongs.length,
            itemBuilder: (ctx, index) {
              final song = allSongs[index];
              return ListTile(
                leading: QueryArtworkWidget(
                  artworkBorder: BorderRadius.circular(10),
                  keepOldArtwork: true,
                  id: song.id,
                  type: ArtworkType.AUDIO,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text(song.title, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  song.artist ?? 'Unknown',
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  musicProvider.addSongToPlaylist(playlistName, song.id);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSongOptions(
    BuildContext context,
    String playlistName,
    SongModel song,
  ) {
    final musicProvider = context.read<MusicProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SizedBox(
          width: MediaQuery.of(context).size.width / 1.3,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10),
                  ),
                  leading: Icon(FlutterRemix.play_fill),
                  title: Text(t(context, 'play')),
                  onTap: () {
                    Navigator.pop(ctx);
                    musicProvider.playSong(song);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10),
                  ),

                  leading: Icon(FlutterRemix.information_line),
                  title: Text(t(context, 'song_details')),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => SongDetailsDialog(song: song),
                    );
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10),
                  ),
                  leading: Icon(
                    FlutterRemix.close_fill,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(t(context, 'Remove')),
                  onTap: () {
                    Navigator.pop(ctx);
                    musicProvider.removeSongFromPlaylist(playlistName, song.id);
                  },
                ),
                const SizedBox(height: 10.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      label: Text(t(context, 'close')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
