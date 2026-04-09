import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';

/// A card tile that shows a track's artwork,
/// with title and subtitle text below.
class TrackCardTile extends StatelessWidget {
  final Track track;

  const TrackCardTile({super.key, required this.track});

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
            child: NixArtwork(
              id: track.id,
              type: ArtworkType.AUDIO,
              fit: BoxFit.cover,
              width: 160.0,
              height: 160.0,
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
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  track.artist,
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
