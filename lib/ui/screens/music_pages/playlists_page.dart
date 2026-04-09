import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';
import 'package:nix/ui/screens/music_pages/views/playlist_view_page.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_playlist_cover.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  void _showPlaylistMenu(BuildContext context, Playlist playlist) {
    final audio = context.read<CurrentMusicProvider>();

    NixDialog.show(
      context: context,
      children: [
        Column(
          children: [
            const SizedBox(height: 8),
            NixPlaylistCover(playlist: playlist, size: 120, radius: 16),
            const SizedBox(height: 16),
            Text(
              playlist.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "${playlist.tracks.length} Tracks",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            CardListTile(
              title: "Edit",
              icon: FlutterRemix.edit_line,
              isFirst: true,
              isLast: false,
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                PlaylistDialogs.showPlaylistActionDialog(
                  context,
                  initialName: playlist.name,
                  playlistId: playlist.id,
                );
              },
            ),
            const SizedBox(height: 2),
            CardListTile(
              title: "Delete",
              icon: FlutterRemix.delete_bin_line,
              isFirst: false,
              isLast: true,
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                PlaylistDialogs.showDeleteConfirmation(
                  context,
                  playlist.id,
                  playlist.name,
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CardListTile(
                    title: "Shuffle",
                    icon: FlutterRemix.shuffle_line,
                    isFirst: true,
                    isLast: true,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      if (playlist.tracks.isNotEmpty) {
                        final shuffled = List<Track>.from(playlist.tracks)
                          ..shuffle();
                        if (!audio.isShuffleEnabled) audio.toggleShuffle();
                        audio.playTrack(shuffled.first, playlist: playlist);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: CardListTile(
                    title: "Play",
                    icon: FlutterRemix.play_fill,
                    isFirst: true,
                    isLast: true,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      if (playlist.tracks.isNotEmpty) {
                        audio.playTrack(
                          playlist.tracks.first,
                          playlist: playlist,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Playlists'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FlutterRemix.add_line),
            tooltip: 'New playlist',
            onPressed: () => PlaylistDialogs.showPlaylistActionDialog(context),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   elevation: 0,
      //   onPressed: () => _showCreateDialog(context),
      //   tooltip: 'New playlist',
      //   child: const Icon(FlutterRemix.add_line),
      // ),
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
                onPressed: () =>
                    PlaylistDialogs.showPlaylistActionDialog(context),
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
            child: ListView.builder(
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
                      PlaylistDialogs.showDeleteConfirmation(
                        context,
                        playlist.id,
                        playlist.name,
                      );
                      return false;
                    },
                    child: CardListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlaylistViewPage(
                            playlistName: playlist.name,
                            playlistId: playlist.id,
                          ),
                        ),
                      ),
                      onLongPress: () {
                        if (context.read<SettingsProvider>().enableHaptics) {
                          HapticFeedback.mediumImpact();
                        }
                        _showPlaylistMenu(context, playlist);
                      },
                      isFirst: index == 0,
                      isLast: index == playlists.length - 1,
                      title: playlist.name,
                      subtitle: '${playlist.tracks.length} tracks',
                      leading: NixPlaylistCover(playlist: playlist, size: 48),
                      trailing: Icon(
                        FlutterRemix.arrow_right_s_line,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
