import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

class SongInfoDialog extends StatelessWidget {
  const SongInfoDialog({
    super.key,
    this.title = "Unknown Title",
    this.artist = "Unknown Artist",
    this.album = "Unknown Album",
    this.duration = "0:00",
    this.size = "0.0 MB",
    this.filePath = "/storage/emulated/0/Music/dummy.mp3",
  });

  final String title;
  final String artist;
  final String album;
  final String duration;
  final String size;
  final String filePath;

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const SongInfoDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              leading: const Icon(FlutterRemix.music_2_line),
              title: const Text("Title"),
              subtitle: Text(title),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              leading: const Icon(FlutterRemix.user_3_line),
              title: const Text("Artist"),
              subtitle: Text(artist),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              leading: const Icon(FlutterRemix.disc_line),
              title: const Text("Album"),
              subtitle: Text(album),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              leading: const Icon(FlutterRemix.time_line),
              title: const Text("Duration"),
              subtitle: Text(duration),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              leading: const Icon(FlutterRemix.hard_drive_2_line),
              title: const Text("Size"),
              subtitle: Text(size),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              leading: const Icon(FlutterRemix.folder_music_line),
              title: const Text("File Path"),
              subtitle: Text(filePath),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
