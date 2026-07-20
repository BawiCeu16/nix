import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/ui/widgets/tiles/track_tile.dart';
import 'package:nix/ui/widgets/tiles/album_card_tile.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/common/nix_action_row.dart';
import 'package:nix/ui/widgets/common/nix_page_header.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainer,
          appBar: AppBar(
            title: const Text('Albums'),
            backgroundColor: colorScheme.surfaceContainer,
            scrolledUnderElevation: 0,
            actions: [
              PopupMenuButton<AlbumSort>(
                icon: const Icon(FlutterRemix.sort_desc),
                tooltip: 'Sort',
                initialValue: _controller.sort,
                onSelected: (v) => _controller.setSort(v),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: AlbumSort.defaultOrder,
                    child: Text('Default'),
                  ),
                  PopupMenuItem(value: AlbumSort.aToZ, child: Text('A → Z')),
                  PopupMenuItem(value: AlbumSort.zToA, child: Text('Z → A')),
                ],
              ),
            ],
          ),
          body: Consumer2<MusicProvider, CurrentMusicProvider>(
            builder: (context, music, currentMusic, child) {
              final albums = _controller.getSortedAlbums(music.albums);

              return NixRefreshableList(
                isEmpty: albums.isEmpty,
                onRefresh: () async => await music.scanDevice(),
                emptyState: const NixEmptyState(
                  icon: FlutterRemix.disc_line,
                  title: "No albums found",
                ),
                child: NixScrollbar(
                  child: GridView.builder(
                    padding: EdgeInsets.only(
                      bottom: NixBottomSpacer.calculateHeight(context),
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
                      final albumTracks = music.getTracksByAlbum(album.title);
                      final firstTrackId = albumTracks.isNotEmpty
                          ? albumTracks.first.id
                          : null;

                      return AlbumCardTile(
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
  late final AlbumTracksController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AlbumTracksController()..initializeCDAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainer,
          appBar: AppBar(
            backgroundColor: colorScheme.surfaceContainer,
            scrolledUnderElevation: 0,
          ),
          body: Consumer2<MusicProvider, CurrentMusicProvider>(
            builder: (context, music, currentMusic, child) {
              final albumTracks = music.getTracksByAlbum(widget.albumTitle);
              final firstTrackId = albumTracks.isNotEmpty
                  ? albumTracks.first.id
                  : 0;

              return NixScrollbar(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount: albumTracks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          NixPageHeader(
                            title: widget.albumTitle,
                            subtitle:
                                '${widget.albumArtist} • ${albumTracks.length} tracks',
                            trackId: firstTrackId,
                          ),
                          NixActionRow(
                            onPlay: () {
                              if (albumTracks.isNotEmpty) {
                                currentMusic.playTrack(
                                  albumTracks.first,
                                  playlist: Playlist(
                                    id: 'album_${widget.albumTitle}',
                                    name: widget.albumTitle,
                                    tracks: List.from(albumTracks),
                                    createdAt: DateTime.now(),
                                  ),
                                );
                              }
                            },
                            onShuffle: () {
                              if (albumTracks.isNotEmpty) {
                                final shuffled = List<Track>.from(albumTracks)..shuffle();
                                currentMusic.playTrack(
                                  shuffled.first,
                                  playlist: Playlist(
                                    id: 'album_${widget.albumTitle}',
                                    name: widget.albumTitle,
                                    tracks: shuffled,
                                    createdAt: DateTime.now(),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    }

                    final trackIndex = index - 1;
                    final track = albumTracks[trackIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TrackTile(
                        track: track,
                        playlistContext: albumTracks,
                        isFirst: trackIndex == 0,
                        isLast: trackIndex == albumTracks.length - 1,
                      ),
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
