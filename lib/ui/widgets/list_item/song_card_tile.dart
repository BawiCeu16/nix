import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:nix/models/music/song.dart';
import '../common/nix_artwork.dart';

/// A card tile that shows a song's artwork from the Hive cached_images box,
/// with title and subtitle text below.
class SongCardTile extends StatelessWidget {
  final Song song;

  const SongCardTile({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.none,
      elevation: 0,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Artwork area ──
          AspectRatio(
            aspectRatio: 1.0,
            child: SizedBox(
              width: double.infinity,
              child: NixArtwork(
                id: song.id,
                type: ArtworkType.AUDIO,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                quality: NixArtworkQuality.medium,
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
