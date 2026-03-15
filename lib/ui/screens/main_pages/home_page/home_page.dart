import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/list_item/song_card_tile.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import '../../music_pages/albums_page.dart';
import '../../music_pages/songs_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── SliverAppBar with greeting ──
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              pinned: false,
              floating: false,
              snap: false,
              expandedHeight: 180,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      "Nix User",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Recently Listened ──
            _SectionHeader(
              title: 'Recently Listened',
              onShowAll: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SongsPage(
                    title: 'Recently Listened',
                    songsSource: () =>
                        context.read<MusicProvider>().recentlyPlayed.songs,
                  ),
                ),
              ),
            ),
            Consumer<MusicProvider>(
              builder: (context, music, child) {
                final recentSongs = music.recentlyPlayed.songs;
                if (recentSongs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      child: Text("No recents yet."),
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      height: 212,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: recentSongs.take(10).length,
                        itemBuilder: (context, index) {
                          final song = recentSongs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5.0,
                            ),
                            child: SizedBox(
                              width: 160.0,
                              child: GestureDetector(
                                onTap: () => context
                                    .read<CurrentMusicProvider>()
                                    .playSong(song),
                                child: SongCardTile(song: song),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Albums ──
            _SectionHeader(
              title: 'Albums',
              onShowAll: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AlbumsPage())),
            ),
            Consumer<MusicProvider>(
              builder: (context, music, child) {
                final albums = music.albums;
                if (albums.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      child: Text("No albums found."),
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      height: 212,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: albums.take(10).length,
                        itemBuilder: (context, index) {
                          final album = albums[index];
                          // Try to get artwork from the first song in this album
                          final albumSongs = music.songs.where(
                            (s) => s.album == album.title,
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5.0,
                            ),
                            child: SizedBox(
                              width: 160.0,
                              child: _AlbumCard(
                                title: album.title,
                                subtitle: album.artist,
                                firstSongUri: albumSongs.isNotEmpty
                                    ? albumSongs.first.uri
                                    : null,
                                onTap: () {
                                  final songs = music.songs
                                      .where((s) => s.album == album.title)
                                      .toList();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SongsPage(
                                        title: album.title,
                                        songsSource: () => songs,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── All Songs ──
            _SectionHeader(
              title: 'All Songs',
              onShowAll: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SongsPage(
                    title: 'All Songs',
                    songsSource: () => context.read<MusicProvider>().songs,
                  ),
                ),
              ),
            ),
            Consumer<MusicProvider>(
              builder: (context, music, child) {
                if (music.isLoading) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final songs = music.songs;
                if (songs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(music.error ?? "No songs found. :("),
                      ),
                    ),
                  );
                }

                return SliverList.builder(
                  itemCount: songs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == songs.length)
                      return const SizedBox(height: 120);
                    final song = songs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 0.0,
                      ),
                      child: TrackTile(
                        track: song,
                        playlistContext: songs,
                        isFirst: index == 0,
                        isLast: index == songs.length - 1,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header with "Show All" button ──
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onShowAll});
  final String title;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, top: 10, right: 8, bottom: 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (onShowAll != null)
              TextButton(onPressed: onShowAll, child: const Text('See All')),
          ],
        ),
      ),
    );
  }
}

// ── Album Card with artwork from Hive ──
class _AlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? firstSongUri;
  final VoidCallback? onTap;

  const _AlbumCard({
    required this.title,
    required this.subtitle,
    this.firstSongUri,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Uint8List? artwork;
    try {
      if (firstSongUri != null && Hive.isBoxOpen('cached_images')) {
        final data = Hive.box('cached_images').get(firstSongUri);
        if (data != null && data is Uint8List) artwork = data;
      }
    } catch (_) {}

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Artwork
            AspectRatio(
              aspectRatio: 1.0,
              child: SizedBox(
                width: double.infinity,
                child: artwork != null
                    ? Image.memory(artwork, fit: BoxFit.cover)
                    : Container(
                        color: colorScheme.secondaryContainer,
                        child: const Center(child: Icon(Icons.album, size: 36)),
                      ),
              ),
            ),
            // Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
