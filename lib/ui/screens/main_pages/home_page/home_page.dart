import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/ui/widgets/list_item/track_card_tile.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/screens/music_pages/albums_page.dart';
import 'package:nix/ui/screens/music_pages/tracks_page.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
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
                    ],
                  ),
                ),
              ),

              // Opt. #5: Single Consumer<MusicProvider> for the entire page.
              // Previously there were 3 separate consumers, tripling rebuilds.
              Consumer<MusicProvider>(
                builder: (context, music, child) {
                  // Opt. #4: Pre-compute album→firstTrackId map ONCE here.
                  // Previously this was an O(n×m) scan per album card per scroll.
                  final Map<String, int> albumFirstTrackId = {};
                  for (final track in music.tracks) {
                    albumFirstTrackId.putIfAbsent(track.album, () => track.id);
                  }

                  final recentTracks = music.recentlyPlayed.tracks;
                  final albums = music.albums;
                  final allTracks = music.tracks;
                  final previewTracks = allTracks.take(6).toList();

                  return SliverMainAxisGroup(
                    slivers: [
                      // ── Recently Listened ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: NixSectionHeader(
                            title: 'Recently Listened',
                            onShowAll: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TracksPage(
                                  title: 'Recently Listened',
                                  tracksSource: () => context
                                      .read<MusicProvider>()
                                      .recentlyPlayed
                                      .tracks,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: recentTracks.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 12.0,
                                ),
                                child: Text('No recents yet.'),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: SizedBox(
                                  height: 212,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: recentTracks.take(10).length,
                                    itemBuilder: (context, index) {
                                      final track = recentTracks[index];
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
                                                tracks: recentTracks,
                                                createdAt: DateTime.now(),
                                              );
                                              currentMusic.playTrack(
                                                track,
                                                playlist: pl,
                                              );
                                            },
                                            child: TrackCardTile(track: track),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),

                      // ── Albums ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: NixSectionHeader(
                            title: 'Albums',
                            onShowAll: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AlbumsPage(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: albums.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 12.0,
                                ),
                                child: Text('No albums found.'),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: SizedBox(
                                  height: 212,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: albums.take(10).length,
                                    itemBuilder: (context, index) {
                                      final album = albums[index];
                                      // Opt. #4: O(1) lookup instead of O(n) scan
                                      final firstTrackId =
                                          albumFirstTrackId[album.title];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5.0,
                                        ),
                                        child: SizedBox(
                                          width: 160.0,
                                          child: _AlbumCard(
                                            title: album.title,
                                            subtitle: album.artist,
                                            firstTrackId: firstTrackId,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AlbumTracksPage(
                                                        albumTitle: album.title,
                                                        albumArtist:
                                                            album.artist,
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
                      ),

                      // ── All Tracks ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: NixSectionHeader(
                            title: 'All Tracks',
                            onShowAll: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TracksPage(
                                  title: 'All Tracks',
                                  tracksSource: () =>
                                      context.read<MusicProvider>().tracks,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (music.isLoading)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      else if (previewTracks.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(music.error ?? 'No tracks found. :('),
                            ),
                          ),
                        )
                      else
                        SliverList.builder(
                          itemCount:
                              previewTracks.length +
                              (allTracks.length > 6 ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index == previewTracks.length &&
                                allTracks.length <= 6) {
                              return const SizedBox(height: 120);
                            }
                            if (index >= previewTracks.length) {
                              return const SizedBox.shrink();
                            }
                            final track = previewTracks[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: TrackTile(
                                track: track,
                                playlistContext: allTracks,
                                isFirst: index == 0,
                                isLast: index == previewTracks.length - 1,
                              ),
                            );
                          },
                        ),
                    ],
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

// ── Album Card with artwork from MediaStore ──
class _AlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? firstTrackId;
  final VoidCallback? onTap;

  const _AlbumCard({
    required this.title,
    required this.subtitle,
    this.firstTrackId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            AspectRatio(
              aspectRatio: 1.0,
              child: firstTrackId != null
                  ? NixArtwork(
                      id: firstTrackId!,
                      type: ArtworkType.AUDIO,
                      borderRadius: BorderRadius.circular(8),
                      fit: BoxFit.cover,
                      width: 160.0,
                      height: 160.0,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(FlutterRemix.disc_line, size: 36),
                      ),
                    ),
            ),
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
