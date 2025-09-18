// File: lib/ui/pages/playlist_detail_screen.dart
import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/%20utils/translator.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/song_details_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistName;

  const PlaylistDetailScreen({super.key, required this.playlistName});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
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
    final songIds = musicProvider.playlists[widget.playlistName] ?? [];
    final songs = musicProvider.songs
        .where((song) => songIds.contains(song.id))
        .toList();

    // find first song for header artwork
    SongModel? headerSong;
    if (songs.isNotEmpty) {
      headerSong = songs.first;
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            actions: [
              // Play whole playlist
              IconButton(
                tooltip: 'Play playlist',
                icon: const Icon(Icons.play_arrow),
                onPressed: () async {
                  try {
                    await context.read<MusicProvider>().playPlaylist(
                      widget.playlistName,
                    );
                  } catch (e) {
                    // ignore
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.playlistName),
              background: headerSong != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        QueryArtworkWidget(
                          id: headerSong.id,
                          type: ArtworkType.AUDIO,
                          artworkBorder: BorderRadius.zero,
                          nullArtworkWidget: Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Icon(Icons.music_note, size: 64),
                          ),
                          keepOldArtwork: true,
                        ),
                        // dark gradient overlay for readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.35),
                                Colors.black.withOpacity(0.25),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: const Center(
                        child: Icon(Icons.music_note, size: 64),
                      ),
                    ),
            ),
          ),

          // If no songs, show empty placeholder
          if (songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: const Center(child: Text('No songs in this playlist.')),
            )
          else
            SliverToBoxAdapter(
              child: LiveList.options(
                options: const LiveOptions(
                  delay: Duration(milliseconds: 50),
                  showItemInterval: Duration(milliseconds: 80),
                  showItemDuration: Duration(milliseconds: 350),
                ),
                itemCount: songs.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index, animation) {
                  final song = songs[index];
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
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
                        title: Text(
                          song.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(song.artist ?? 'Unknown Artist'),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showSongOptions(
                            context,
                            widget.playlistName,
                            song,
                          ),
                        ),
                        onTap: () async {
                          // Play the playlist and seek to the tapped song so upcoming order matches playlist
                          try {
                            await context.read<MusicProvider>().playPlaylist(
                              widget.playlistName,
                            );
                            final idx = context
                                .read<MusicProvider>()
                                .currentAudioQueue
                                .indexWhere((s) => s.id == song.id);
                            if (idx != -1) {
                              await context
                                  .read<MusicProvider>()
                                  .audioPlayer
                                  .seek(Duration.zero, index: idx);
                              await context
                                  .read<MusicProvider>()
                                  .audioPlayer
                                  .play();
                            }
                          } catch (e) {
                            // ignore
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _showFab ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => _showAddSongDialog(context),
          ),
        ),
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
                  musicProvider.addSongToPlaylist(widget.playlistName, song.id);
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: const Icon(Icons.play_arrow),
                  title: Text(t(context, 'play')),
                  onTap: () {
                    Navigator.pop(ctx);
                    musicProvider.playSong(song);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: const Icon(Icons.info_outline),
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
                    borderRadius: BorderRadius.circular(10),
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
