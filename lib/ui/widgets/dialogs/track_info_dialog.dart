import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/buttons/expressive_button.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';

class TrackInfoDialog extends StatelessWidget {
  const TrackInfoDialog({
    super.key,
    this.title = "Unknown Title",
    this.artist = "Unknown Artist",
    this.album = "Unknown Album",
    this.duration = "0:00",
    this.size = "0.0 MB",
    this.filePath = "/storage/emulated/0/Music/dummy.mp3",
    this.trackId,
  });

  final String title;
  final String artist;
  final String album;
  final String duration;
  final String size;
  final String filePath;
  final int? trackId;

  static void show(
    BuildContext context, {
    String title = "Unknown Title",
    String artist = "Unknown Artist",
    String album = "Unknown Album",
    String duration = "0:00",
    String size = "0.0 MB",
    String filePath = "/storage/emulated/0/Music/music.flac",
    int? trackId,
  }) {
    NixDialog.show(
      context: context,
      title: title,
      subtitle: artist,
      trackId: trackId,
      children: [
        CardListTile(
          title: "Album",
          subtitle: album,
          icon: FlutterRemix.disc_line,
          isFirst: true,
          onTap: () {},
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Duration",
          subtitle: duration,
          icon: FlutterRemix.time_line,
          onTap: () {},
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Size",
          subtitle: size,
          icon: FlutterRemix.hard_drive_2_line,
          onTap: () {},
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "File Path",
          subtitle: filePath,
          icon: FlutterRemix.folder_music_line,
          isLast: true,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ExpressiveButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text("CLOSE"),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // This build method is now rarely used directly as we use .show()
    return const SizedBox.shrink();
  }
}
