import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/widgets/tiles/album_card_tile.dart';
import 'package:nix/ui/widgets/tiles/track_tile.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/common/nix_action_row.dart';
import 'package:nix/ui/widgets/common/nix_page_header.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/cd_widget.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';
import 'package:nix/ui/screens/music/controllers/albums_controller.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  late final AlbumsPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AlbumsPageController();
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
            title: const Text('Albums'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            scrolledUnderElevation: 0,
            actions: [
              PopupMenuButton<AlbumSort>(
                icon: const Icon(FlutterRemix.sort_desc),
                tooltip: 'Sort',
                initialValue: _controller.sort,
                onSelected: _controller.setSort,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: AlbumSort.name,
                    child: Text('Album Name'),
                  ),
                  PopupMenuItem(
                    value: AlbumSort.artist,
                    child: Text('Artist Name'),
                  ),
                  PopupMenuItem(
                    value: AlbumSort.trackCount,
                    child: Text('Track Count'),
                  ),
                ],
              ),
            ],
          ),
          body: Consumer<MusicProvider>(
            builder: (context, music, child) {
              final sortedAlbums = _controller.getSortedAlbums(music.albums);

              return NixRefreshableList(
                isEmpty: sortedAlbums.isEmpty,
                onRefresh: () async => await music.scanDevice(),
                emptyState: const NixEmptyState(
                  icon: FlutterRemix.disc_line,
                  title: "No albums found",
                ),
                child: NixScrollbar(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: sortedAlbums.length,
                    itemBuilder: (context, index) {
                      final album = sortedAlbums[index];
                      final firstTrackId =
                          music.albumFirstTrackId[album.title];
                      return AlbumCardTile(
                        title: album.title,
                        subtitle: album.artist,
                        firstTrackId: firstTrackId,
                        onTap: () => _controller.openAlbumDetails(
                          context,
                          album.title,
                          album.artist,
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

class AlbumTracksPage extends StatefulWidget {
  final String albumTitle;
  final String albumArtist;

  const AlbumTracksPage({
    super.key,
    required this.albumTitle,
    required this.albumArtist,
  });

  @override
  State<AlbumTracksPage> createState() => _AlbumTracksPageState();
}

class _AlbumTracksPageState extends State<AlbumTracksPage> {
  late final AlbumsPageController _controller;
  CDCoverState _cdState = CDCoverState.closed;

  @override
  void initState() {
    super.initState();
    _controller = AlbumsPageController();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _cdState = CDCoverState.halfOpen;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useCdArtworkStyle = context.select<SettingsProvider, bool>(
      (s) => s.useCdArtworkStyle,
    );
    final splitCdWhenHalfOpen = context.select<SettingsProvider, bool>(
      (s) => s.splitCdWhenHalfOpen,
    );
    final rotateCdWhenPlaying = context.select<SettingsProvider, bool>(
      (s) => s.rotateCdWhenPlaying,
    );
    final cdRotationSpeed = context.select<SettingsProvider, double>(
      (s) => s.cdRotationSpeed,
    );

    final isPlaying = context.select<CurrentMusicProvider, bool>(
      (p) => p.isPlaying && p.currentTrack?.album == widget.albumTitle,
    );

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          appBar: AppBar(
            title: Text(widget.albumTitle),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            scrolledUnderElevation: 0,
            centerTitle: true,
          ),
          body: Consumer<MusicProvider>(
            builder: (context, music, child) {
              final tracks = music.tracks
                  .where((t) => t.album == widget.albumTitle)
                  .toList();
              final firstTrackId = tracks.isNotEmpty ? tracks.first.id : null;

              final Widget cdWidget = useCdArtworkStyle
                  ? Hero(
                      tag: 'album_cd_${widget.albumTitle}',
                      child: NixCustomizableCDWidget(
                        size: 220,
                        state: _cdState,
                        splitWhenHalfOpen: splitCdWhenHalfOpen,
                        isSpinning: isPlaying && rotateCdWhenPlaying,
                        rotateSpeed: cdRotationSpeed,
                        seedId: widget.albumTitle,
                        onTap: () {
                          setState(() {
                            _cdState = _cdState == CDCoverState.halfOpen
                                ? CDCoverState.closed
                                : CDCoverState.halfOpen;
                          });
                        },
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
                      ),
                    )
                  : (firstTrackId != null
                      ? NixArtwork(
                          id: firstTrackId,
                          type: ArtworkType.AUDIO,
                          width: 240,
                          height: 240,
                          borderRadius: BorderRadius.circular(16),
                        )
                      : Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ));

              return NixScrollbar(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: tracks.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return NixPageHeader(
                        title: widget.albumTitle,
                        subtitle:
                            '${widget.albumArtist} • ${tracks.length} Tracks',
                        customArtwork: cdWidget,
                        actionRow: NixActionRow(
                          onShuffle: () => _controller.shuffleAlbum(
                            context,
                            tracks,
                            widget.albumTitle,
                          ),
                          onPlay: () {
                            if (tracks.isNotEmpty) {
                              _controller.playAlbumTrack(
                                context,
                                tracks.first,
                                tracks,
                                widget.albumTitle,
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
