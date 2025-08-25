import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/pages/playlist_detail_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final playlists = musicProvider.playlists;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        centerTitle: true,
        title: const Text('Playlists'),
      ),

      body: playlists.isEmpty
          ? const Center(child: Text('No playlists created yet.'))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (ctx, index) {
                  final playlistName = playlists.keys.elementAt(index);
                  final songIds = playlists[playlistName]!;
                  return Card(
                    elevation: 0,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(10),
                      ),
                      title: Text(
                        playlistName,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${songIds.length} songs'),
                      trailing: PopupMenuButton(
                        elevation: 0,
                        icon: Icon(FlutterRemix.more_2_fill),
                        onSelected: (value) {
                          if (value == 'delete') {
                            musicProvider.deletePlaylist(playlistName);
                          } else if (value == 'rename') {
                            _showRenamePlaylistDialog(context, playlistName);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'rename',

                            child: Row(
                              children: [
                                Icon(FlutterRemix.edit_fill),
                                SizedBox(width: 10),
                                Text('Rename'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  FlutterRemix.delete_bin_fill,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(
                              playlistName: playlistName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: musicProvider.currentSong != null ? 80 : 16,
          // 80px if MiniPlayer is showing, else normal
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreatePlaylistDialog(context),
          icon: const Icon(Icons.add),
          label: const Text("Create Playlist"),
          elevation: 0,
        ),
      ),
    );
  }

  //Playlist Function
  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter playlist name'),
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<MusicProvider>().createPlaylist(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  //Rename Function
  void _showRenamePlaylistDialog(BuildContext context, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                context.read<MusicProvider>().renamePlaylist(oldName, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
