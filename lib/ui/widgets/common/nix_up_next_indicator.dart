import 'package:flutter/material.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/miniplayer/models/animation_data.dart';

class NixUpNextIndicator extends StatelessWidget {
  final PlayerAnimationData data;

  const NixUpNextIndicator({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (!settings.upNextIndicator) return const SizedBox();

    final musicProvider = context.watch<CurrentMusicProvider>();
    final nextTrack = musicProvider.nextTrack;
    if (nextTrack == null) return const SizedBox();

    return StreamBuilder<Duration>(
      stream: musicProvider.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = musicProvider.duration ?? Duration.zero;

        final remaining = duration.inSeconds - position.inSeconds;
        final triggerTime = settings.upNextIndicatorTime;

        // Calculate opacity based on proximity to end and expansion progress
        // Only show if remaining time is less than or equal to trigger time
        // AND player is sufficiently expanded (bounceClampedProgress > 0)
        double timeOpacity = 0.0;
        if (remaining > 0 && remaining <= triggerTime) {
          // Smooth fade in over 2 seconds
          timeOpacity = (triggerTime - remaining) / 2.0;
          timeOpacity = timeOpacity.clamp(0.0, 1.0);
        } else if (remaining <= 0 && duration != Duration.zero) {
          // Keep it visible if it somehow goes past (should skip anyway)
          timeOpacity = 1.0;
        }

        final finalOpacity = (timeOpacity * data.opacity).clamp(0.0, 1.0);

        if (finalOpacity == 0) return const SizedBox();

        return Opacity(
          opacity: finalOpacity,
          child: Container(
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                SizedBox(width: 5.0),
                // Mini Artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: NixArtwork(
                    id: nextTrack.id,
                    type: ArtworkType.AUDIO,
                    borderRadius: BorderRadius.circular(8.0),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'UP NEXT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        nextTrack.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        nextTrack.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
