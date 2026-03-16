import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/screens/music_pages/views/playlist_view_page.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    NixDialog.show(
      context: context,
      title: "New Playlist",
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Playlist Name",
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      context.read<MusicProvider>().createPlaylist(name, []);
                    }
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Create"),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Playlists'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FlutterRemix.add_line),
            tooltip: 'New playlist',
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        onPressed: () => _showCreateDialog(context),
        tooltip: 'New playlist',
        child: const Icon(FlutterRemix.add_line),
      ),
      body: Consumer<MusicProvider>(
        builder: (context, music, child) {
          final playlists = music.playlists;

          if (playlists.isEmpty) {
            return const Center(child: Text("No playlists found."));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 120, top: 10),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  leading: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    child: Icon(FlutterRemix.play_list_line, color: Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                  title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${playlist.songs.length} tracks'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PlaylistViewPage(playlistName: playlist.name)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
