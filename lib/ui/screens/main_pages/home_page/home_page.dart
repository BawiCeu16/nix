import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/providers/settings_provider.dart';

import 'package:nix/ui/widgets/list_item/track_card_tile.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/album.dart';
import 'package:nix/models/music/playlist.dart';

import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/screens/music_pages/albums_page.dart';
import 'package:nix/ui/screens/music_pages/tracks_page.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:expressive_refresh/expressive_refresh.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/styles/cd_widget.dart';

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
                expandedHeight: 200,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  title: Selector<UserProvider, String>(
                    selector: (_, p) => p.userName,
                    builder: (context, userName, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: GoogleFonts.getFont(
                              'Special Gothic Expanded One',
                              textStyle: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w300,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 0),
                          Text(
                            userName,
                            style: GoogleFonts.getFont(
                              'Special Gothic Expanded One',
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              SliverMainAxisGroup(
                slivers: [
                  // ── Recently Listened ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: NixSectionHeader(
                        title: 'Recently Listened',
                        topPadding: 20,
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
                  Selector<MusicProvider, List<Track>>(
                    selector: (_, p) => p.recentlyPlayed.tracks,
                    builder: (context, tracks, _) {
                      if (tracks.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 12.0,
                            ),
                            child: Text('No recents yet.'),
                          ),
                        );
                      }
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: SizedBox(
                            height: 215,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: tracks.take(10).length,
                              itemBuilder: (context, index) {
                                final track = tracks[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                  ),
                                  child: SizedBox(
                                    width: 161.0,
                                    child: GestureDetector(
                                      onTap: () {
                                        final currentMusic = context
                                            .read<CurrentMusicProvider>();
                                        final pl = Playlist(
                                          id: 'recently_played',
                                          name: 'Recently Listened',
                                          tracks: tracks,
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
                      );
                    },
                  ),

                  // ── Albums ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: NixSectionHeader(
                        title: 'Albums',
                        topPadding: 32,
                        onShowAll: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AlbumsPage()),
                        ),
                      ),
                    ),
                  ),
                  Selector<MusicProvider, List<Album>>(
                    selector: (_, p) => p.albums,
                    builder: (context, albums, _) {
                      if (albums.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 12.0,
                            ),
                            child: Text('No albums found.'),
                          ),
                        );
                      }
                      final albumFirstTrackId = context
                          .read<MusicProvider>()
                          .albumFirstTrackId;
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: SizedBox(
                            height: 213,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: albums.take(10).length,
                              itemBuilder: (context, index) {
                                final album = albums[index];
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
                                            builder: (_) => AlbumTracksPage(
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

                  // ── All Tracks ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: NixSectionHeader(
                        title: 'All Tracks',
                        topPadding: 32,
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
                  Selector<MusicProvider, (bool, String?, List<Track>)>(
                    selector: (_, p) => (p.isLoading, p.error, p.tracks),
                    builder: (context, data, _) {
                      final isLoading = data.$1;
                      final error = data.$2;
                      final tracks = data.$3;

                      if (isLoading) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }
                      if (tracks.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(error ?? 'No tracks found. :('),
                            ),
                          ),
                        );
                      }
                      return SliverList.builder(
                        itemCount: tracks.take(6).length,
                        itemBuilder: (context, index) {
                          final previewTracks = tracks.take(6).toList();
                          final track = previewTracks[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: TrackTile(
                              track: track,
                              playlistContext: tracks,
                              isFirst: index == 0,
                              isLast: index == previewTracks.length - 1,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const NixBottomSpacer.sliver(),
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
    final settings = context.watch<SettingsProvider>();

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
              child: Hero(
                tag: 'album_cd_$title',
                child: settings.useCdArtworkStyle
                    ? NixCustomizableCDWidget(
                        size: 160,
                        state: CDCoverState.closed,
                        splitWhenHalfOpen: false,
                        seedId: title,
                        coverImage: Stack(
                          fit: StackFit.expand,
                          children: [
                            NixArtwork(
                              id: firstTrackId ?? 0,
                              type: ArtworkType.AUDIO,
                              fit: BoxFit.cover,
                            ),
                            Transform.scale(
                              scale: 1.15,
                              child: Image.asset(
                                'assets/cd_effects/cd_cover.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                        discImage: NixArtwork(
                          id: firstTrackId ?? 0,
                          type: ArtworkType.AUDIO,
                          fit: BoxFit.cover,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: NixArtwork(
                          id: firstTrackId ?? 0,
                          type: ArtworkType.AUDIO,
                          fit: BoxFit.cover,
                        ),
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
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
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
