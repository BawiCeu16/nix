import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/models/music/album.dart';
import 'package:nix/models/music/song.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/common/nix_action_row.dart';
import 'package:nix/ui/widgets/common/nix_page_header.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';
import '../../widgets/common/nix_artwork.dart';

enum _AlbumSort { defaultOrder, aToZ, zToA }

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  _AlbumSort _sort = _AlbumSort.defaultOrder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Albums'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<_AlbumSort>(
            icon: const Icon(FlutterRemix.sort_desc),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _AlbumSort.defaultOrder,
                child: Text('Default'),
              ),
              PopupMenuItem(value: _AlbumSort.aToZ, child: Text('A → Z')),
              PopupMenuItem(value: _AlbumSort.zToA, child: Text('Z → A')),
            ],
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, music, child) {
          List<Album> albums = List.from(music.albums);
          if (_sort == _AlbumSort.aToZ) {
            albums.sort((a, b) => a.title.compareTo(b.title));
          } else if (_sort == _AlbumSort.zToA) {
            albums.sort((a, b) => b.title.compareTo(a.title));
          }

          return NixRefreshableList(
            isEmpty: albums.isEmpty,
            onRefresh: () async => await music.scanDevice(),
            emptyState: const NixEmptyState(
              icon: FlutterRemix.disc_line,
              title: "No albums found",
            ),
            child: GridView.builder(
              padding: const EdgeInsets.only(
                bottom: 120,
                left: 16,
                right: 16,
                top: 8,
              ),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                final albumSongs = music.getSongsByAlbum(album.title);
                final firstSongId =
                    albumSongs.isNotEmpty ? albumSongs.first.id : null;

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AlbumSongsPage(
                          albumTitle: album.title,
                          albumArtist: album.artist,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    clipBehavior: Clip.none,
                    color: Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                        child: NixArtwork(
                          id: firstSongId ?? 0,
                          type: ArtworkType.AUDIO,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          quality: NixArtworkQuality.medium, // Optimized high fidelity
                        ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                album.artist,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class AlbumSongsPage extends StatelessWidget {
  final String albumTitle;
  final String albumArtist;

  const AlbumSongsPage({
    super.key,
    required this.albumTitle,
    required this.albumArtist,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: Text(albumTitle),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: Consumer<MusicProvider>(
        builder: (context, music, child) {
          final songs = music.getSongsByAlbum(albumTitle);
          final firstSongId = songs.isNotEmpty ? songs.first.id : null;

          return NixRefreshableList(
            isEmpty: songs.isEmpty,
            onRefresh: () async => await music.scanDevice(),
            emptyState: const NixEmptyState(
              icon: FlutterRemix.music_2_line,
              title: "No songs found in this album",
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: songs.length + 2, // Header + Songs + Bottom Padding
              itemBuilder: (context, index) {
                if (index == 0) {
                  return NixPageHeader(
                    title: albumTitle,
                    subtitle: "$albumArtist • ${songs.length} Songs",
                    songId: firstSongId,
                    fallbackIcon: FlutterRemix.disc_line,
                    actionRow: NixActionRow(
                      onShuffle: () {
                        final audio = context.read<CurrentMusicProvider>();
                        final shuffled = List<Song>.from(songs)..shuffle();
                        if (!audio.isShuffleEnabled) audio.toggleShuffle();
                        audio.playSong(shuffled.first);
                      },
                      onPlay: () {
                        context.read<CurrentMusicProvider>().playSong(
                              songs.first,
                            );
                      },
                      playLabel: "Play All",
                    ),
                  );
                }

                if (index == songs.length + 1) {
                  return const SizedBox(height: 120);
                }

                final song = songs[index - 1];
                return TrackTile(
                  track: song,
                  playlistContext: songs,
                  isFirst: index == 1,
                  isLast: index == songs.length,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
