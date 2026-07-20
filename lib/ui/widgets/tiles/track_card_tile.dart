import 'package:flutter/material.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/core/format.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';

/// A card tile that shows a track's artwork,
/// with title and subtitle text below.
class TrackCardTile extends StatelessWidget {
  final Track track;

  const TrackCardTile({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final showResume = context.select<SettingsProvider, bool>(
      (s) => s.resumeFromPlayedDuration,
    );

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
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                ValueListenableBuilder<Box<int>>(
                  valueListenable: Hive.box<int>(HiveKeys.trackPositionsBox)
                      .listenable(keys: [track.id]),
                  builder: (context, box, _) {
                    final savedMs = showResume ? box.get(track.id) : null;
                    final totalDurationStr = Duration(milliseconds: track.duration).shortFormat();
                    final durationStr = savedMs != null
                        ? '${Duration(milliseconds: savedMs).shortFormat()} / $totalDurationStr'
                        : totalDurationStr;

                    return Text(
                      '${track.artist} • $durationStr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
