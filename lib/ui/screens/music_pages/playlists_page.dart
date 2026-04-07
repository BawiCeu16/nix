import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';
import 'package:nix/ui/screens/music_pages/views/playlist_view_page.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  void _showPlaylistMenu(BuildContext context, String id, String name) {
    NixDialog.show(
      context: context,
      title: name,
      children: [
        CardListTile(
          title: "Rename",
          icon: FlutterRemix.edit_line,
          isFirst: true,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            PlaylistDialogs.showPlaylistActionDialog(
              context,
              initialName: name,
              playlistId: id,
            );
          },
        ),
        const SizedBox(height: 2),
        CardListTile(
          title: "Delete",
          icon: FlutterRemix.delete_bin_line,
          isLast: true,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            PlaylistDialogs.showDeleteConfirmation(context, id, name);
          },
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

          if (playlists.isEmpty) {
            return NixEmptyState(
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
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            physics: const BouncingScrollPhysics(),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
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
                        builder: (_) =>
                            PlaylistViewPage(playlistName: playlist.name),
                      ),
                    ),
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showPlaylistMenu(context, playlist.id, playlist.name);
                    },
                    isFirst: index == 0,
                    isLast: index == playlists.length - 1,
                    title: playlist.name,
                    subtitle: '${playlist.songs.length} tracks',
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.secondaryContainer,
                      ),
                      child: Icon(
                        FlutterRemix.play_list_line,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    trailing: Icon(
                      FlutterRemix.arrow_right_s_line,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
