import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/buttons/expressive_button.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/services/snackbar_service.dart';

class PlaylistDialogs {
  /// Handles both creating a new playlist and renaming an existing one.
  static void showPlaylistActionDialog(
    BuildContext context, {
    String? initialName,
    String? playlistId,
    List<Track> tracks = const [],
  }) {
    final controller = TextEditingController(text: initialName);
    final isEditing = playlistId != null;
    final music = context.read<MusicProvider>();

    NixDialog.show(
      context: context,
      title: isEditing ? "Rename Playlist" : "New Playlist",
      children: [
        Column(
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Playlist Name",
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ExpressiveToneButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: ExpressiveButton(
                      onPressed: () {
                        final name = controller.text.trim();
                        if (name.isNotEmpty) {
                          if (isEditing) {
                            music.renamePlaylist(
                              playlistId,
                              name,
                            );
                          } else {
                            music.createPlaylist(
                              name,
                              tracks,
                            );
                          }
                        }
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Text(isEditing ? "Save" : "Create"),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Unified delete confirmation dialog.
  static void showDeleteConfirmation(
    BuildContext context,
    String id,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => SizedBox(
        width: 200,
        child: AlertDialog(
          title: const Text("Delete Playlist?"),
          content: Text("Are you sure you want to delete \"$name\"?"),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ExpressiveToneButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 8),
            ExpressiveButton(
              onPressed: () {
                context.read<MusicProvider>().deletePlaylist(id);
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the playlist picker for adding a track to a playlist.
  static void showPlaylistPicker(BuildContext context, Track track) {
    final music = context.read<MusicProvider>();
    final playlists = music.playlists;

    NixDialog.show(
      context: context,
      title: "Add to Playlist",
      subtitle: track.title,
      children: [
        if (playlists.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text("No playlists found.")),
          )
        else
          ...playlists.map((playlist) {
            final isFirst = playlist == playlists.first;
            final isLast = playlist == playlists.last;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CardListTile(
                  title: playlist.name,
                  subtitle: '${playlist.tracks.length} tracks',
                  icon: FlutterRemix.play_list_add_line,
                  isFirst: isFirst,
                  isLast: isLast,
                  onTap: () async {
                    final success = await music.addTrackToPlaylist(
                      playlist.id,
                      track,
                    );
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                      if (success) {
                        context.showSuccessSnackBar(
                          'Added to ${playlist.name}',
                        );
                      } else {
                        context.showErrorSnackBar(
                          'Already in ${playlist.name}',
                        );
                      }
                    }
                  },
                ),
                if (!isLast) const SizedBox(height: 2.5),
              ],
            );
          }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ExpressiveButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              showPlaylistActionDialog(context, tracks: [track]);
            },
            child: const Text("CREATE NEW PLAYLIST"),
          ),
        ),
      ],
    );
  }
}
