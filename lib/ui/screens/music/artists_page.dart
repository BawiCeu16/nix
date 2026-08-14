import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/tiles/track_tile.dart';
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
                  NixSortMenuItem(value: ArtistSort.trackCount, label: 'Track Count'),
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
                  child: ListView.builder(
                    cacheExtent: 600,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: sortedArtists.length + 1,
                    itemBuilder: (context, index) {
                      if (index == sortedArtists.length) {
                        return const NixBottomSpacer();
                      }

                      final artist = sortedArtists[index];
                      final tracks = music.tracks
                          .where((t) => t.artist == artist.name)
                          .toList();
                      final firstTrackId =
                          tracks.isNotEmpty ? tracks.first.id : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2.5),
                        child: CardListTile(
                          onTap: () => _controller.openArtistDetails(
                            context,
                            artist.name,
                          ),
                          isFirst: index == 0,
                          isLast: index == sortedArtists.length - 1,
                          title: artist.name,
                          subtitle: '${artist.numberOfTracks} tracks',
                          leading: firstTrackId != null
                              ? NixArtwork(
                                  id: firstTrackId,
                                  type: ArtworkType.AUDIO,
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(100),
                                )
                              : const CircleAvatar(
                                  radius: 24,
                                  child: Icon(FlutterRemix.user_4_line),
                                ),
                          trailing: Icon(
                            FlutterRemix.arrow_right_s_line,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
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
                  cacheExtent: 600,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: tracks.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return NixPageHeader(
                        title: widget.artistName,
                        subtitle: '${tracks.length} Tracks',
                        customArtwork: firstTrackId != null
                            ? NixArtwork(
                                id: firstTrackId,
                                type: ArtworkType.AUDIO,
                                width: 300,
                                height: 300,
                                borderRadius: BorderRadius.circular(24),
                              )
                            : Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  FlutterRemix.user_4_line,
                                  size: 100,
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
                    return TrackTile(
                      track: track,
                      playlistContext: tracks,
                      isFirst: index == 1,
                      isLast: index == tracks.length,
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
