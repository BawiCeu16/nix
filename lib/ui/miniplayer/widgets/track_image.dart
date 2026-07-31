import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/providers/sleep_timer_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/settings/timer_gesture.dart';
import 'package:nix/ui/widgets/dialogs/sleep_timer_dialog.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/widgets/common/nix_up_next_indicator.dart';
import 'package:nix/core/format.dart';
import 'package:nix/core/math_utils.dart';
import 'package:nix/ui/miniplayer/models/animation_data.dart';

class TrackImage extends StatelessWidget {
  final AnimationController sAnim;
  final double sMaxOffset;
  final double siParallax;
  final bool bounceUp;
  final double maxOffset;
  final double topInset;
  final bool bounceDown;
  final Size screenSize;
  final PlayerAnimationData data;
  final Animation<double> lyricsAnim;

  const TrackImage({
    super.key,
    required this.sAnim,
    required this.sMaxOffset,
    required this.siParallax,
    required this.bounceUp,
    required this.maxOffset,
    required this.topInset,
    required this.bounceDown,
    required this.screenSize,
    required this.data,
    required this.lyricsAnim,
  });

  Widget _buildSingleArtwork(
    BuildContext context,
    Track? song,
    BorderRadius radius,
  ) {
    if (song != null) {
      return RepaintBoundary(
        child: NixArtwork(
          id: song.id,
          type: ArtworkType.AUDIO,
          borderRadius: radius,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: radius,
      ),
      child: Center(
        child: Icon(
          FlutterRemix.music_2_fill,
          size: 40,
          color: Theme.of(
            context,
          ).colorScheme.onPrimaryContainer.withValues(alpha: .5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = context.select<CurrentMusicProvider, Track?>(
      (p) => p.currentTrack,
    );
    final nextSong = context.select<CurrentMusicProvider, Track?>(
      (p) => p.nextTrack,
    );
    final previousSong = context.select<CurrentMusicProvider, Track?>(
      (p) => p.previousTrack,
    );

    final double maxStandardSize = screenSize.width - 46.0;
    final double availableHeight =
        screenSize.height - (maxOffset / 2.30) - (topInset + 80.0) - 24.0;
    final double expandedSize = availableHeight < maxStandardSize
        ? availableHeight.clamp(120.0, maxStandardSize)
        : maxStandardSize;

    return AnimatedBuilder(
      animation: Listenable.merge([sAnim, lyricsAnim]),
      builder: (context, child) {
        final double sVal = sAnim.value;
        final borderRadius = BorderRadius.circular(
          rangeProgress(a: 100.0, b: 15.0, c: data.bounceClampedProgress),
        );

        return Transform.translate(
          offset: Offset(
            -sVal * sMaxOffset / siParallax,
            !bounceUp
                ? (-maxOffset + topInset + 108.0) *
                      (!bounceDown
                          ? data.queueProgress
                          : (1 - data.bounceProgress))
                : 0.0,
          ),
          child: Transform.translate(
            offset: Offset(
              0,
              data.bottomOffset +
                  rangeProgress(
                    a: -maxOffset / 2.30 * data.bounceProgress.clamp(0, 2),
                    b: -maxOffset / 3.6 * data.bounceProgress.clamp(0, 2),
                    c: lyricsAnim.value,
                  ) +
                  (90.0 * lyricsAnim.value * data.bounceClampedProgress),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.0 * (1 - data.bounceClampedProgress))
                  .add(
                    EdgeInsets.only(
                      left: rangeProgress(
                        a: 22.0 * data.bounceClampedProgress * lyricsAnim.value,
                        b: 20.0 * data.bounceClampedProgress,
                        c: lyricsAnim.value,
                      ),
                    ),
                  ),
              child: Align(
                alignment:
                    Alignment.lerp(
                      Alignment.bottomLeft,
                      Alignment.bottomCenter,
                      data.bounceClampedProgress * (1 - lyricsAnim.value),
                    ) ??
                    Alignment.bottomLeft,
                child: SizedBox(
                  height: rangeProgress(
                    a: 82.0,
                    b: rangeProgress(
                      a: expandedSize,
                      b: 60.0,
                      c: lyricsAnim.value,
                    ),
                    c: data.bounceClampedProgress,
                  ),
                  width: rangeProgress(
                    a: 82.0,
                    b: rangeProgress(
                      a: expandedSize,
                      b: 60.0,
                      c: lyricsAnim.value,
                    ),
                    c: data.bounceClampedProgress,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      12.0 * (1 - data.bounceClampedProgress),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 1. Next Track Artwork (sliding from right when swiping left, sVal > 0)
                        if (sVal > 0.001)
                          Positioned.fill(
                            child: Transform.translate(
                              offset: Offset(sMaxOffset, 0),
                              child: _buildSingleArtwork(
                                context,
                                nextSong,
                                borderRadius,
                              ),
                            ),
                          ),

                        // 2. Previous Track Artwork (sliding from left when swiping right, sVal < 0)
                        if (sVal < -0.001)
                          Positioned.fill(
                            child: Transform.translate(
                              offset: Offset(-sMaxOffset, 0),
                              child: _buildSingleArtwork(
                                context,
                                previousSong,
                                borderRadius,
                              ),
                            ),
                          ),

                        // 3. Current Track Artwork
                        Positioned.fill(
                          child: _buildSingleArtwork(
                            context,
                            currentSong,
                            borderRadius,
                          ),
                        ),

                        // Sleep Timer Indicator
                        Consumer<SleepTimerProvider>(
                          builder: (context, timer, _) {
                            if (!timer.isActive) return const SizedBox();
                            final opacity =
                                ((data.opacity - data.queueClampedProgress) *
                                        (1 - lyricsAnim.value))
                                    .clamp(0.0, 1.0);
                            if (opacity == 0) return const SizedBox();

                            return Positioned(
                              top: 12,
                              left: 12,
                              child: Opacity(
                                opacity: opacity,
                                child: GestureDetector(
                                  onTap:
                                      context
                                              .read<SettingsProvider>()
                                              .timerGesture ==
                                          TimerGesture.tap
                                      ? () => SleepTimerDialog.show(context)
                                      : null,
                                  onLongPress:
                                      context
                                              .read<SettingsProvider>()
                                              .timerGesture ==
                                          TimerGesture.longPress
                                      ? () => SleepTimerDialog.show(context)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          FlutterRemix.timer_2_line,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          timer.remainingTime?.shortFormat() ??
                                              "00:00",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Up Next Indicator
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Opacity(
                            opacity: (1 - lyricsAnim.value).clamp(0.0, 1.0),
                            child: NixUpNextIndicator(data: data),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
