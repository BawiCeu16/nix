// File: lib/ui/pages/playlist_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/pages/playlist_detail_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final ScrollController _scrollController = ScrollController();
  double _lastOffset = 0.0;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > _lastOffset + 20 && _showFab) {
      setState(() => _showFab = false);
    } else if (offset < _lastOffset - 20 && !_showFab) {
      setState(() => _showFab = true);
    }
    _lastOffset = offset;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final playlists = musicProvider.playlists;

    // convert to entries list so iteration is stable and easier to use
    final entries = playlists.entries.toList();

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        centerTitle: true,
        title: const Text('Playlists'),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: entries.isEmpty
          ? const Center(child: Text('No playlists created yet.'))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (ctx, index) {
                  final playlistName = entries[index].key;
                  final songIds = entries[index].value;

                  // Find the first song model for this playlist (if available)
                  SongModel? firstSong;
                  if (songIds.isNotEmpty) {
                    final firstId = songIds.first;
                    try {
                      firstSong = musicProvider.songs.firstWhere(
                        (s) => s.id == firstId,
                      );
                    } catch (e) {
                      firstSong = null;
                    }
                  }

                  return Card(
                    elevation: 0,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      // Leading: show artwork of the playlist's first song if available
                      leading: SizedBox(
                        height: 56,
                        width: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: firstSong != null
                              ? QueryArtworkWidget(
                                  id: firstSong.id,
                                  type: ArtworkType.AUDIO,
                                  keepOldArtwork: true,
                                  nullArtworkWidget: Container(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    child: const Icon(Icons.music_note),
                                  ),
                                )
                              : Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: const Icon(Icons.music_note),
                                ),
                        ),
                      ),
                      title: Text(
                        playlistName,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${songIds.length} songs'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Play button: minimal, calls provider to play the playlist
                          IconButton(
                            tooltip: 'Play playlist',
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () async {
                              try {
                                await context
                                    .read<MusicProvider>()
                                    .playPlaylist(playlistName);
                              } catch (e) {
                                // swallow errors silently; you can log if needed
                              }
                            },
                          ),
                          PopupMenuButton(
                            elevation: 0,
                            icon: const Icon(FlutterRemix.more_2_fill),
                            onSelected: (value) {
                              if (value == 'delete') {
                                context.read<MusicProvider>().deletePlaylist(
                                  playlistName,
                                );
                              } else if (value == 'rename') {
                                _showRenamePlaylistDialog(
                                  context,
                                  playlistName,
                                );
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: const [
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      floatingActionButton: AnimatedSlide(
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _showFab ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              bottom: musicProvider.currentSong != null ? 80 : 16,
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _showCreatePlaylistDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Create Playlist"),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  // Playlist create dialog
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

  // Rename dialog
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
