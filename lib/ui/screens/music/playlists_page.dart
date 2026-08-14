import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_playlist_cover.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';
import 'package:nix/ui/screens/music/controllers/playlists_controller.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
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
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          appBar: AppBar(
            title: const Text('Playlists'),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            scrolledUnderElevation: 0,
            actions: [
              IconButton(
                icon: const Icon(FlutterRemix.add_line),
                tooltip: 'New playlist',
                onPressed: () => _controller.createNewPlaylist(context),
              ),
            ],
          ),
          body: Consumer<MusicProvider>(
            builder: (context, music, child) {
              final playlists = music.playlists;
              final colorScheme = Theme.of(context).colorScheme;
              return NixRefreshableList(
                isEmpty: playlists.isEmpty,
                onRefresh: () async => await music.scanDevice(),
                emptyState: NixEmptyState(
                  icon: FlutterRemix.play_list_2_line,
                  title: "No playlists yet",
                  action: ExpressiveToneButton(
                    onPressed: () => _controller.createNewPlaylist(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FlutterRemix.add_line, size: 20),
                        SizedBox(width: 8),
                        Text("Create Playlist"),
                      ],
                    ),
                  ),
                ),
                child: NixScrollbar(
                  child: ListView.builder(
                    cacheExtent: 600,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: playlists.length + 1,
                    itemBuilder: (context, index) {
                      if (index == playlists.length) {
                        return const NixBottomSpacer();
                      }
                      final playlist = playlists[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Dismissible(
                          key: ValueKey(playlist.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
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
                          confirmDismiss: (direction) async {
                            _controller.deletePlaylist(context, playlist);
                            return false;
                          },
                          child: CardListTile(
                            onTap: () =>
                                _controller.openPlaylistView(context, playlist),
                            onLongPress: () {
                              if (context
                                  .read<SettingsProvider>()
                                  .enableHaptics) {
                                HapticFeedback.mediumImpact();
                              }
                              _controller.showPlaylistMenu(context, playlist);
                            },
                            isFirst: index == 0,
                            isLast: index == playlists.length - 1,
                            title: playlist.name,
                            subtitle: '${playlist.tracks.length} tracks',
                            leading: NixPlaylistCover(
                              playlist: playlist,
                              size: 48,
                            ),
                            trailing: Icon(
                              FlutterRemix.arrow_right_s_line,
                              color: colorScheme.onSurfaceVariant,
                            ),
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
