import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/sleep_timer_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/settings/timer_gesture.dart';
import 'package:nix/ui/widgets/dialogs/sleep_timer_dialog.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/widgets/common/nix_up_next_indicator.dart';
import '../../../core/format.dart';
import '../../../core/math_utils.dart';
import '../models/animation_data.dart';

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

  @override
  Widget build(BuildContext context) {
    final currentSong = context.watch<CurrentMusicProvider>().currentTrack;

    return AnimatedBuilder(
      animation: Listenable.merge([sAnim, lyricsAnim]),
      builder: (context, child) {
        return Opacity(
          opacity: 1 - sAnim.value.abs(),
          child: Transform.translate(
            offset: Offset(
              -sAnim.value * sMaxOffset / siParallax,
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
                          a: 22.0 * data.bounceClampedProgress,
                          b: 20.0 * data.bounceClampedProgress,
                          c: lyricsAnim.value,
                        ),
                      ),
                    ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                    height: rangeProgress(
                      a: 82.0,
                      b: rangeProgress(
                        a: screenSize.width - 46.0,
                        b: 60.0,
                        c: lyricsAnim.value,
                      ),
                      c: data.bounceClampedProgress,
                    ),
                    width: rangeProgress(
                      a: 82.0,
                      b: rangeProgress(
                        a: screenSize.width - 46.0,
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
                        children: [
                          currentSong != null
                              ? NixArtwork(
                                  id: currentSong.id,
                                  type: ArtworkType.AUDIO,
                                  borderRadius: BorderRadius.circular(
                                    rangeProgress(
                                      a: 100.0,
                                      b: 15.0,
                                      c: data.bounceClampedProgress,
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      rangeProgress(
                                        a: 100.0,
                                        b: 15.0,
                                        c: data.bounceClampedProgress,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      FlutterRemix.music_2_fill,
                                      size: 40,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: .5),
                                    ),
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
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
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
                                            timer.remainingTime
                                                    ?.shortFormat() ??
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
                          Opacity(
                            opacity: (1 - lyricsAnim.value).clamp(0.0, 1.0),
                            child: NixUpNextIndicator(data: data),
                          ),
                        ],
                      ),
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
