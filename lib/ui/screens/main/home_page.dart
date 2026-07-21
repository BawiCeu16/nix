import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix_button/nix_button.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/ui/theme/nix_typography.dart';
import 'package:nix/ui/widgets/tiles/track_card_tile.dart';
import 'package:nix/ui/widgets/tiles/album_card_tile.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/album.dart';
import 'package:nix/ui/widgets/tiles/track_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:expressive_refresh/expressive_refresh.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/screens/main/controllers/home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomePageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomePageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
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
              onRefresh: () => _controller.refreshLibrary(context),
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
                      title: Selector<
                        UserProvider,
                        ({String userName, int avatarIndex})
                      >(
                        selector: (_, p) =>
                            (userName: p.userName, avatarIndex: p.avatarIndex),
                        builder: (context, data, _) {
                          final userName = data.userName;
                          final avatarIndex = data.avatarIndex;
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _controller.getGreeting(),
                                      style: NixTypography.specialGothicLabelMedium(
                                        context,
                                        colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 0),
                                    Text(
                                      userName,
                                      style: NixTypography.specialGothicHeadlineSmall(
                                        context,
                                        colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _controller.openProfile(context),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: UserProvider
                                      .avatarColors[avatarIndex]
                                      .withValues(alpha: 0.2),
                                  child: Icon(
                                    UserProvider.avatarIcons[avatarIndex],
                                    color: UserProvider.avatarColors[avatarIndex],
                                    size: 20,
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
                      // ── Quick Actions ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: const NixSectionHeader(
                            title: 'Quick Actions',
                            topPadding: 20,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              NixButton(
                                customBackgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.7),
                                icon: const Icon(FlutterRemix.music_2_fill),
                                label: const Text("All Songs"),
                                enableAnimations: true,
                                onPressed: () => _controller.openAllSongs(context),
                              ),
                              const SizedBox(width: 12),
                              NixButton(
                                customBackgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.7),
                                icon: const Icon(FlutterRemix.disc_fill),
                                label: const Text("Albums"),
                                enableAnimations: true,
                                onPressed: () => _controller.openAlbums(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // ── Recently Listened ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: NixSectionHeader(
                            title: 'Recently Listened',
                            topPadding: 20,
                            onShowAll: () =>
                                _controller.openRecentlyListened(context),
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
                          final recentTracks = tracks.take(10).toList();
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: SizedBox(
                                height: 215,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: recentTracks.length,
                                  itemBuilder: (context, index) {
                                    final track = recentTracks[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                      ),
                                      child: SizedBox(
                                        width: 161.0,
                                        child: GestureDetector(
                                          onTap: () => _controller.playRecentTrack(
                                            context,
                                            track,
                                            tracks,
                                          ),
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
                            onShowAll: () => _controller.openAlbums(context),
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
                          final recentAlbums = albums.take(10).toList();
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: SizedBox(
                                height: 213,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: recentAlbums.length,
                                  itemBuilder: (context, index) {
                                    final album = recentAlbums[index];
                                    final firstTrackId =
                                        albumFirstTrackId[album.title];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                      ),
                                      child: SizedBox(
                                        width: 160.0,
                                        child: AlbumCardTile(
                                          title: album.title,
                                          subtitle: album.artist,
                                          firstTrackId: firstTrackId,
                                          onTap: () => _controller.openAlbumDetails(
                                            context,
                                            album.title,
                                            album.artist,
                                          ),
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
                            onShowAll: () => _controller.openAllSongs(context),
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
                                child: Center(child: LoadingIndicatorM3E()),
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
                          final previewTracks = tracks.take(6).toList();
                          return SliverList.builder(
                            itemCount: previewTracks.length,
                            itemBuilder: (context, index) {
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
      },
    );
  }
}
