import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:hive/hive.dart';
import 'package:nix/models/music/song.dart';

/// A card tile that shows a song's artwork from the Hive cached_images box,
/// with title and subtitle text below.
class SongCardTile extends StatelessWidget {
  final Song song;

  const SongCardTile({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Uint8List? artwork;
    try {
      if (Hive.isBoxOpen('cached_images')) {
        final data = Hive.box('cached_images').get(song.uri);
        if (data != null && data is Uint8List) artwork = data;
      }
    } catch (_) {}

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Artwork area ──
          AspectRatio(
            aspectRatio: 1.0,
            child: SizedBox(
              width: double.infinity,
              child: artwork != null
                  ? Image.memory(artwork, fit: BoxFit.cover)
                  : Container(
                      color: colorScheme.secondaryContainer,
                      child: const Center(
                        child: Icon(FlutterRemix.music_2_line, size: 36),
                      ),
                    ),
            ),
          ),
          // ── Text area ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
