import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/tiles/track_tile.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/common/nix_action_row.dart';
import 'package:nix/ui/widgets/common/nix_page_header.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_playlist_cover.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';
import 'package:nix/ui/screens/music/controllers/playlists_controller.dart';

class PlaylistViewPage extends StatefulWidget {
  final String playlistName;
  final String? playlistId;

  const PlaylistViewPage({
    super.key,
    this.playlistName = "Unknown Playlist",
    this.playlistId,
  });

  @override
  State<PlaylistViewPage> createState() => _PlaylistViewPageState();
}

class _PlaylistViewPageState extends State<PlaylistViewPage> {
  late final PlaylistsPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlaylistsPageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainer,
          appBar: AppBar(
            title: Text(widget.playlistName),
            backgroundColor: colorScheme.surfaceContainer,
            scrolledUnderElevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(FlutterRemix.edit_line),
                onPressed: () => PlaylistDialogs.showPlaylistActionDialog(
                  context,
                  initialName: widget.playlistName,
                  playlistId: widget.playlistId,
                ),
              ),
            ],
          ),
          body: Consumer<MusicProvider>(
            builder: (context, music, child) {
              Playlist? pl;
              bool isSystemPlaylist = false;

              if (widget.playlistId == "recently_played" ||
                  widget.playlistName == "Recently Listened") {
                pl = music.recentlyPlayed;
                isSystemPlaylist = true;
              } else if (widget.playlistId == "favorites" ||
                  widget.playlistName == "Favorites") {
                pl = music.favorites;
                isSystemPlaylist = true;
              } else if (widget.playlistId == "top_played" ||
                  widget.playlistName == "Top Listened") {
                pl = music.topPlayed;
                isSystemPlaylist = true;
              } else {
                pl = music.playlists.firstWhere(
                  (p) =>
                      p.id == widget.playlistId ||
                      p.name == widget.playlistName,
                  orElse: () => music.playlists.first,
                );
              }

              final tracks = List<Track>.from(pl.tracks);

              if (tracks.isEmpty && isSystemPlaylist) {
                return const NixEmptyState(
                  icon: FlutterRemix.music_2_line,
                  title: "No tracks here yet",
                );
              }

              return NixScrollbar(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: !isSystemPlaylist,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: tracks.length + 2,
                  onReorderItem: (oldIndex, newIndex) {
                    if (isSystemPlaylist || pl == null) return;
                    _controller.reorderPlaylistTracks(
                      context: context,
                      playlistId: pl.id,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                      totalTracksCount: tracks.length,
                    );
                  },
                  proxyDecorator: (child, index, animation) =>
                      Material(color: Colors.transparent, child: child),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        key: const ValueKey('header'),
                        children: [
                          NixPageHeader(
                            title: pl!.name,
                            subtitle: "${tracks.length} Tracks",
                            customArtwork: NixPlaylistCover(
                              playlist: pl,
                              size: 300,
                              radius: 24,
                            ),
                            actionRow: NixActionRow(
                              onShuffle: () => _controller.shufflePlaylist(
                                context,
                                pl!,
                              ),
                              onPlay: () => _controller.playPlaylist(
                                context,
                                pl!,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    if (index == tracks.length + 1) {
                      return const NixBottomSpacer(key: ValueKey('padding'));
                    }

                    final trackIndex = index - 1;
                    final track = tracks[trackIndex];

                    Widget tile = TrackTile(
                      track: track,
                      playlistContext: tracks,
                      isFirst: trackIndex == 0,
                      isLast: trackIndex == tracks.length - 1,
                    );

                    if (!isSystemPlaylist) {
                      return Dismissible(
                        key: ValueKey('${pl!.id}_${track.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.only(right: 24),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            FlutterRemix.delete_bin_line,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                        onDismissed: (_) => _controller.removeTrackFromPlaylist(
                          context: context,
                          playlistId: pl!.id,
                          track: track,
                        ),
                        child: tile,
                      );
                    }

                    return Container(
                      key: ValueKey('track_${track.id}'),
                      child: tile,
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
