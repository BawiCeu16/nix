import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:nix/ui/widgets/buttons/expressive_button.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/core/utils/nix_icons.dart';

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

    int? selectedIcon = isEditing
        ? music.playlists.firstWhere((p) => p.id == playlistId).iconCodePoint
        : null;
    int? selectedColor = isEditing
        ? music.playlists.firstWhere((p) => p.id == playlistId).colorValue
        : null;

    NixDialog.show(
      context: context,
      title: isEditing ? "Rename Playlist" : "New Playlist",
      children: [
        StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(context).colorScheme;
            return Column(
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Playlist Name",
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      "Appearance",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Icon Picker
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildIconOption(
                        context,
                        null,
                        selectedIcon,
                        (icon) => setDialogState(() => selectedIcon = icon),
                      ),
                      ...[
                        FlutterRemix.play_list_2_line.codePoint,
                        FlutterRemix.heart_3_line.codePoint,
                        FlutterRemix.star_line.codePoint,
                        FlutterRemix.fire_line.codePoint,
                        FlutterRemix.music_2_line.codePoint,
                        FlutterRemix.mic_2_line.codePoint,
                        FlutterRemix.headphone_line.codePoint,
                        FlutterRemix.disc_line.codePoint,
                      ].map(
                        (codePoint) => _buildIconOption(
                          context,
                          codePoint,
                          selectedIcon,
                          (icon) => setDialogState(() => selectedIcon = icon),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Color Picker
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildColorOption(
                        context,
                        null,
                        selectedColor,
                        (color) => setDialogState(() => selectedColor = color),
                      ),
                      ...[
                        Colors.redAccent.value,
                        Colors.blueAccent.value,
                        Colors.greenAccent.value,
                        Colors.purpleAccent.value,
                        Colors.orangeAccent.value,
                        Colors.tealAccent.value,
                        Colors.pinkAccent.value,
                      ].map(
                        (colorVal) => _buildColorOption(
                          context,
                          colorVal,
                          selectedColor,
                          (color) => setDialogState(() => selectedColor = color),
                        ),
                      ),
                    ],
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
                                  icon: selectedIcon,
                                  color: selectedColor,
                                );
                              } else {
                                music.createPlaylist(
                                  name,
                                  tracks,
                                  icon: selectedIcon,
                                  color: selectedColor,
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
            );
          },
        ),
      ],
    );
  }

  static Widget _buildIconOption(
    BuildContext context,
    int? codePoint,
    int? current,
    Function(int?) onSelect,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = current == codePoint;
    return GestureDetector(
      onTap: () => onSelect(codePoint),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          codePoint != null
              ? NixIcons.getPlaylistIcon(codePoint)
              : FlutterRemix.image_line,
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          size: 20,
        ),
      ),
    );
  }

  static Widget _buildColorOption(
    BuildContext context,
    int? colorValue,
    int? current,
    Function(int?) onSelect,
  ) {
    final isSelected = current == colorValue;
    return GestureDetector(
      onTap: () => onSelect(colorValue),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: colorValue != null ? Color(colorValue) : Colors.grey,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: colorValue == null
            ? const Icon(FlutterRemix.close_line, size: 16, color: Colors.white)
            : null,
      ),
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
                    final success =
                        await music.addTrackToPlaylist(playlist.id, track);
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Added to ${playlist.name}'
                                : 'Already in ${playlist.name}',
                          ),
                          backgroundColor: success
                              ? null
                              : Theme.of(context).colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
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
