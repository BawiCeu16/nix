import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';

import 'package:nix/ui/widgets/tiles/m3e_track_tile.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/common/nix_action_row.dart';
import 'package:nix/ui/widgets/common/nix_page_header.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';
import 'package:nix/ui/screens/music/controllers/artists_controller.dart';
import 'package:nix/ui/widgets/common/nix_sort_widget.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  late final ArtistsPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ArtistsPageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          appBar: AppBar(
            title: const Text('Artists'),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            scrolledUnderElevation: 0,
            actions: [
              NixSortWidget<ArtistSort>(
                currentSort: _controller.sort,
                isAscending: _controller.isAscending,
                onSortSelected: _controller.setSort,
                onToggleOrder: _controller.toggleOrder,
                items: const [
                  NixSortMenuItem(value: ArtistSort.name, label: 'Artist Name'),
                  NixSortMenuItem(
                    value: ArtistSort.trackCount,
                    label: 'Track Count',
                  ),
                ],
              ),
            ],
          ),
          body: Consumer<MusicProvider>(
            builder: (context, music, child) {
              final sortedArtists = _controller.getSortedArtists(music.artists);

              return NixRefreshableList(
                isEmpty: sortedArtists.isEmpty,
                onRefresh: () async => await music.scanDevice(),
                emptyState: const NixEmptyState(
                  icon: FlutterRemix.user_4_line,
                  title: "No artists found",
                ),
                child: NixScrollbar(
                  child: CustomScrollView(
                    scrollCacheExtent: const .pixels(600.0),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: context
                                    .watch<SettingsProvider>()
                                    .artistGridCrossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.8,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final crossAxisCount = context
                                .watch<SettingsProvider>()
                                .artistGridCrossAxisCount;
                            final isDense = crossAxisCount > 2;
                            final isVeryDense = crossAxisCount > 3;

                            final double titleSize = isVeryDense
                                ? 12
                                : (isDense ? 14 : 16);
                            final double subtitleSize = isVeryDense
                                ? 10
                                : (isDense ? 12 : 13);
                            final double iconSize = isVeryDense
                                ? 24
                                : (isDense ? 36 : 48);
                            final double spacerHeight = isDense ? 8 : 12;
                            final double cardPadding = isVeryDense
                                ? 4.0
                                : (isDense ? 8.0 : 12.0);

                            final artist = sortedArtists[index];
                            final tracks = music.tracks
                                .where((t) => t.artist == artist.name)
                                .toList();
                            final firstTrackId = tracks.isNotEmpty
                                ? tracks.first.id
                                : null;

                            return Card(
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () => _controller.openArtistDetails(
                                  context,
                                  artist.name,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Hero(
                                            tag:
                                                'artist_artwork_${artist.name}',
                                            child: firstTrackId != null
                                                ? NixArtwork(
                                                    id: firstTrackId,
                                                    type: ArtworkType.AUDIO,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          1000,
                                                        ),
                                                  )
                                                : Container(
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      FlutterRemix.user_4_line,
                                                      size: iconSize,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: spacerHeight),
                                      Text(
                                        artist.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: titleSize,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${artist.numberOfTracks} tracks',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: subtitleSize,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }, childCount: sortedArtists.length),
                        ),
                      ),
                      const SliverToBoxAdapter(child: NixBottomSpacer()),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ArtistTracksPage extends StatefulWidget {
  final String artistName;

  const ArtistTracksPage({super.key, required this.artistName});

  @override
  State<ArtistTracksPage> createState() => _ArtistTracksPageState();
}

class _ArtistTracksPageState extends State<ArtistTracksPage> {
  late final ArtistsPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ArtistsPageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          appBar: AppBar(
            title: Text(widget.artistName),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            scrolledUnderElevation: 0,
            centerTitle: true,
          ),
          body: Consumer<MusicProvider>(
            builder: (context, music, child) {
              final tracks = music.tracks
                  .where((t) => t.artist == widget.artistName)
                  .toList();
              final firstTrackId = tracks.isNotEmpty ? tracks.first.id : null;

              return NixScrollbar(
                child: ListView.builder(
                  scrollCacheExtent: const .pixels(600.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: tracks.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return NixPageHeader(
                        title: widget.artistName,
                        subtitle: '${tracks.length} Tracks',
                        customArtwork: Hero(
                          tag: 'artist_artwork_${widget.artistName}',
                          child: firstTrackId != null
                              ? NixArtwork(
                                  id: firstTrackId,
                                  type: ArtworkType.AUDIO,
                                  width: 300,
                                  height: 300,
                                  borderRadius: BorderRadius.circular(1000),
                                )
                              : Container(
                                  width: 300,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    FlutterRemix.user_4_line,
                                    size: 100,
                                  ),
                                ),
                        ),
                        actionRow: NixActionRow(
                          onShuffle: () => _controller.shuffleArtist(
                            context,
                            tracks,
                            widget.artistName,
                          ),
                          onPlay: () {
                            if (tracks.isNotEmpty) {
                              _controller.playArtistTrack(
                                context,
                                tracks.first,
                                tracks,
                                widget.artistName,
                              );
                            }
                          },
                        ),
                      );
                    }

                    if (index == tracks.length + 1) {
                      return const NixBottomSpacer();
                    }

                    final track = tracks[index - 1];
                    return M3ETrackTile(
                      track: track,
                      playlistContext: tracks,
                      isFirst: index == 1,
                      isLast: index == tracks.length,
                      index: index - 1,
                      totalCount: tracks.length,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
