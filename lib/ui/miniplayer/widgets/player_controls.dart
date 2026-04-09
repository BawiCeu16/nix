import 'package:flutter/material.dart';
import 'package:nix/core/format.dart';
import 'package:provider/provider.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:wave_slider_flutter/wave_slider_flutter.dart';
import '../../../core/math_utils.dart';
import '../models/animation_data.dart';

class PlayerControls extends StatelessWidget {
  final double maxOffset;
  final double topInset;
  final bool bounceUp;
  final bool bounceDown;
  final Color onSecondary;
  final Size screenSize;
  final VoidCallback onTogglePlay;
  final Animation<double> playPauseAnim;
  final PlayerAnimationData data;

  const PlayerControls({
    super.key,
    required this.maxOffset,
    required this.topInset,
    required this.bounceUp,
    required this.bounceDown,
    required this.onSecondary,
    required this.screenSize,
    required this.onTogglePlay,
    required this.playPauseAnim,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final currentMusic = context.watch<CurrentMusicProvider>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // CONTROLS & PLAY BUTTON
        Material(
          type: MaterialType.transparency,
          child: Transform.translate(
            offset: Offset(
              0,
              data.bottomOffset +
                  (-maxOffset / 7.5 * data.bounceProgress) +
                  ((-maxOffset + topInset + 80.0) *
                      (!bounceUp
                          ? !bounceDown
                                ? data.queueProgress
                                : (1 - data.bounceProgress)
                          : 0.0)),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.0 * data.inverseClampedProgress),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    if (data.fastOpacity > 0.0)
                      Opacity(
                        opacity: data.fastOpacity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                24.0 *
                                (16 *
                                        (!bounceDown
                                            ? data.inverseClampedProgress
                                            : 0.0) +
                                    1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                iconSize: 28.0,
                                icon: Icon(
                                  FlutterRemix.shuffle_line,
                                  color: currentMusic.isShuffleEnabled
                                      ? Theme.of(context).colorScheme.primary
                                      : onSecondary,
                                ),
                                onPressed: () => currentMusic.toggleShuffle(),
                              ),
                              IconButton(
                                iconSize: 28.0,
                                icon: Icon(
                                  currentMusic.isRepeatEnabled
                                      ? FlutterRemix.repeat_one_line
                                      : FlutterRemix.repeat_2_line,
                                  color: currentMusic.isRepeatEnabled
                                      ? Theme.of(context).colorScheme.primary
                                      : onSecondary,
                                ),
                                onPressed: () => currentMusic.toggleRepeat(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (data.fastOpacity > 0.0)
                      Opacity(
                        opacity: data.fastOpacity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                84.0 *
                                (2 *
                                        (!bounceDown
                                            ? data.inverseClampedProgress
                                            : 0.0) +
                                    1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                iconSize: 36.0,
                                icon: Icon(
                                  FlutterRemix.skip_back_fill,
                                  color: onSecondary,
                                ),
                                onPressed: () => currentMusic.playPrevious(),
                              ),
                              IconButton(
                                iconSize: 36.0,
                                icon: Icon(
                                  FlutterRemix.skip_forward_fill,
                                  color: onSecondary,
                                ),
                                onPressed: () => currentMusic.playNext(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding:
                          EdgeInsets.all(
                            12.0 * data.inverseClampedProgress,
                          ).add(
                            EdgeInsets.only(
                              right: !bounceDown
                                  ? !bounceUp
                                        ? screenSize.width *
                                                  data.reverseClampedProgress /
                                                  2 -
                                              80 *
                                                  data.reverseClampedProgress /
                                                  2 +
                                              (data.queueProgress * 24.0)
                                        : screenSize.width *
                                                  data.clampedProgress /
                                                  2 -
                                              80 * data.clampedProgress / 2
                                  : screenSize.width *
                                            data.bounceClampedProgress /
                                            2 -
                                        80 * data.bounceClampedProgress / 2 +
                                        (data.queueProgress * 24.0),
                            ),
                          ),
                      child: SizedBox(
                        height: rangeProgress(
                          a: 60.0,
                          b: 80.0,
                          c: data.reverseProgress,
                        ),
                        width: rangeProgress(
                          a: 60.0,
                          b: 80.0,
                          c: data.reverseProgress,
                        ),
                        child: FloatingActionButton(
                          onPressed: onTogglePlay,
                          elevation: 0,
                          focusElevation: 0,
                          hoverElevation: 0,
                          highlightElevation: 0,
                          disabledElevation: 0,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.0),
                          ),
                          child: AnimatedIcon(
                            progress: playPauseAnim,
                            icon: AnimatedIcons.play_pause,
                            size: rangeProgress(
                              a: 32.0,
                              b: 46.0,
                              c: data.reverseProgress,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // SLIDER
        if (data.fastOpacity > 0.0)
          Opacity(
            opacity: data.fastOpacity,
            child: Transform.translate(
              offset: Offset(
                0,
                data.bottomOffset + (-maxOffset / 4.3 * data.progress),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<PlayerState>(
                        stream: currentMusic.playerStateStream,
                        builder: (context, stateSnap) {
                          final isPlaying = stateSnap.data?.playing ?? false;
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0.0,
                              end: isPlaying ? 3.0 : 0.0,
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            builder: (context, amplitude, _) {
                              return StreamBuilder<Duration>(
                                stream: currentMusic.positionStream,
                                builder: (context, posSnap) {
                                  final pos = posSnap.data ?? Duration.zero;
                                  final dur =
                                      currentMusic.duration ?? Duration.zero;
                                  final sliderVal = dur.inMilliseconds > 0
                                      ? (pos.inMilliseconds /
                                                dur.inMilliseconds)
                                            .clamp(0.0, 1.0)
                                      : 0.0;
                                  return WaveSlider(
                                    value: sliderVal,
                                    theme: WaveSliderTheme(
                                      activeColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      thumbColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      inactiveColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: .3),
                                      amplitude: amplitude,

                                      frequency: 15,
                                      strokeWidth: 2.8,
                                      thumbShape: WaveSliderThumbShape.bar,
                                    ),
                                    onChanged: (v) {
                                      if (dur.inMilliseconds > 0) {
                                        currentMusic.seek(
                                          Duration(
                                            milliseconds:
                                                (v * dur.inMilliseconds)
                                                    .round(),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        child: StreamBuilder<Duration>(
                          stream: currentMusic.positionStream,
                          builder: (context, posSnap) {
                            final pos = posSnap.data ?? Duration.zero;
                            final dur = currentMusic.duration ?? Duration.zero;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  pos.shortFormat(),
                                  style: TextStyle(color: onSecondary),
                                ),
                                Text(
                                  dur.shortFormat(),
                                  style: TextStyle(color: onSecondary),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
