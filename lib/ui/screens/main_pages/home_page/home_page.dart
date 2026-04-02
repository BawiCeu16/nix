import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/ui/widgets/list_item/song_card_tile.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import '../../music_pages/albums_page.dart';
import '../../music_pages/songs_page.dart';

import 'package:expressive_refresh/expressive_refresh.dart';

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
    final user = context.watch<UserProvider>();

    final brightness = Theme.of(context).brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: ExpressiveRefreshIndicator(
          onRefresh: () async {
            await context.read<MusicProvider>().scanDevice();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── SliverAppBar with greeting ──
              SliverAppBar(
                systemOverlayStyle: brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light.copyWith(
                        statusBarColor: Colors.transparent,
                      )
                    : SystemUiOverlayStyle.dark.copyWith(
                        statusBarColor: Colors.transparent,
                      ),
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                pinned: false,
                floating: false,
                snap: false,
                expandedHeight: 180,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              user.userName,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // CircleAvatar(
                      //   radius: 20,
                      //   backgroundColor: UserProvider
                      //       .avatarColors[user.avatarIndex]
                      //       .withValues(alpha: 0.2),
                      //   child: Icon(
                      //     UserProvider.avatarIcons[user.avatarIndex],
                      //     color: UserProvider.avatarColors[user.avatarIndex],
                      //     size: 20,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),

              // ── Recently Listened ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: NixSectionHeader(
                    title: 'Recently Listened',
                    onShowAll: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SongsPage(
                          title: 'Recently Listened',
                          songsSource: () => context
                              .read<MusicProvider>()
                              .recentlyPlayed
                              .songs,
                        ),
                      ),
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
                                  onTap: () {
                                    final currentMusic = context
                                        .read<CurrentMusicProvider>();
                                    final pl = Playlist(
                                      id: 'recently_played',
                                      name: 'Recently Listened',
                                      songs: recentSongs,
                                      createdAt: DateTime.now(),
                                    );
                                    currentMusic.playSong(song, playlist: pl);
                                  },
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: NixSectionHeader(
                    title: 'Albums',
                    onShowAll: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AlbumsPage()),
                    ),
                  ),
                ),
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
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AlbumSongsPage(
                                          albumTitle: album.title,
                                          albumArtist: album.artist,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: NixSectionHeader(
                    title: 'All Songs',
                    onShowAll: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SongsPage(
                          title: 'All Songs',
                          songsSource: () =>
                              context.read<MusicProvider>().songs,
                        ),
                      ),
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

                  final allSongs = music.songs;
                  final songs = allSongs.take(6).toList();
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
                    itemCount: songs.length + (allSongs.length > 6 ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index == songs.length && allSongs.length <= 6) {
                        return const SizedBox(height: 120);
                      }
                      if (index >= songs.length) return const SizedBox.shrink();
                      final song = songs[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 0.0,
                        ),
                        child: TrackTile(
                          track: song,
                          playlistContext: allSongs,
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
                        child: const Center(
                          child: Icon(FlutterRemix.disc_line, size: 36),
                        ),
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
