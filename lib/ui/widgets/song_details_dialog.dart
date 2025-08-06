import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/%20utils/translator.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter/services.dart';

class SongDetailsDialog extends StatelessWidget {
  final SongModel song;

  const SongDetailsDialog({super.key, required this.song});

  //
  String formatSize(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    return '${(bytes / mb).toStringAsFixed(2)} MB';
  }

  String formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(20),
      ),
      //padding for all inside of dialog
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkHeight: 80,
                  artworkWidth: 80,
                  artworkBorder: BorderRadius.circular(10),
                  nullArtworkWidget: Card(
                    elevation: 0,
                    child: Padding(
                      padding: EdgeInsetsGeometry.all(15),
                      child: const Icon(Icons.music_note, size: 60),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Song title and artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        song.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      Text(
                        song.artist ?? t(context, 'unknown'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Album Art
            const SizedBox(height: 10.0),

            // Details
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Text(
                            t(context, 'album'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(song.album ?? 'Unknown'),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            t(context, 'duration'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(formatDuration(song.duration ?? 0)),
                        ],
                      ),

                      Row(
                        children: [
                          Text(
                            t(context, 'size'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(formatSize(song.size)),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "${t(context, t(context, 'file_type'))}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(song.fileExtension),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            t(context, 'path'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: Text(song.data)),
                          Tooltip(
                            message: "Copy path",
                            child: IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: song.data),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Path copied!")),
                                );
                              },
                              icon: const Icon(FlutterRemix.clipboard_line),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Close Button
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t(context, t(context, 'close'))),
                ),
                SizedBox(width: 5),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
