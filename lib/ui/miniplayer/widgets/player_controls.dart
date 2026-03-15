import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import '../../../core/math_utils.dart';

class PlayerControls extends StatelessWidget {
  final double bottomOffset;
  final double maxOffset;
  final double bounceProgressValue;
  final double topInset;
  final bool bounceUp;
  final bool bounceDown;
  final double queueProgressValue;
  final double inverseClampedProgressValue;
  final double fastOpacity;
  final Color onSecondary;
  final double reverseClampedProgressValue;
  final double clampedProgressValue;
  final Size screenSize;
  final double reverseProgressValue;
  final VoidCallback onTogglePlay;
  final Animation<double> playPauseAnim;
  final double progressValue;
  final double bounceClampedProgressValue;

  const PlayerControls({
    super.key,
    required this.bottomOffset,
    required this.maxOffset,
    required this.bounceProgressValue,
    required this.topInset,
    required this.bounceUp,
    required this.bounceDown,
    required this.queueProgressValue,
    required this.inverseClampedProgressValue,
    required this.fastOpacity,
    required this.onSecondary,
    required this.reverseClampedProgressValue,
    required this.clampedProgressValue,
    required this.screenSize,
    required this.reverseProgressValue,
    required this.onTogglePlay,
    required this.playPauseAnim,
    required this.progressValue,
    required this.bounceClampedProgressValue,
  });

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final currentMusic = context.watch<CurrentMusicProvider>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // CONTROLS & MORPHING PLAY BUTTON
        Material(
          type: MaterialType.transparency,
          child: Transform.translate(
            offset: Offset(
              0,
              bottomOffset +
                  (-maxOffset / 7.0 * bounceProgressValue) +
                  ((-maxOffset + topInset + 80.0) *
                      (!bounceUp
                          ? !bounceDown
                                ? queueProgressValue
                                : (1 - bounceProgressValue)
                          : 0.0)),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.0 * inverseClampedProgressValue),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    if (fastOpacity > 0.0)
                      Opacity(
                        opacity: fastOpacity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.0 * (16 * (!bounceDown ? inverseClampedProgressValue : 0.0) + 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                iconSize: 28.0,
                                icon: Icon(
                                  Icons.shuffle,
                                  color: currentMusic.isShuffleEnabled
                                      ? Theme.of(context).colorScheme.primary
                                      : onSecondary,
                                ),
                                onPressed: () => currentMusic.toggleShuffle(),
                              ),
                              IconButton(
                                iconSize: 28.0,
                                icon: Icon(
                                  Icons.repeat,
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
                    if (fastOpacity > 0.0)
                      Opacity(
                        opacity: fastOpacity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 84.0 * (2 * (!bounceDown ? inverseClampedProgressValue : 0.0) + 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                iconSize: 40.0,
                                icon: Icon(Icons.skip_previous_rounded, color: onSecondary),
                                onPressed: () => currentMusic.playPrevious(),
                              ),
                              IconButton(
                                iconSize: 40.0,
                                icon: Icon(Icons.skip_next_rounded, color: onSecondary),
                                onPressed: () => currentMusic.playNext(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding:
                          EdgeInsets.all(12.0 * inverseClampedProgressValue).add(
                            EdgeInsets.only(
                              right: !bounceDown
                                  ? !bounceUp
                                        ? screenSize.width * reverseClampedProgressValue / 2 -
                                            80 * reverseClampedProgressValue / 2 +
                                            (queueProgressValue * 24.0)
                                        : screenSize.width * clampedProgressValue / 2 -
                                            80 * clampedProgressValue / 2
                                  : screenSize.width * bounceClampedProgressValue / 2 -
                                      80 * bounceClampedProgressValue / 2 +
                                      (queueProgressValue * 24.0),
                            ),
                          ),
                      child: SizedBox(
                        height: rangeProgress(a: 60.0, b: 80.0, c: reverseProgressValue),
                        width: rangeProgress(a: 60.0, b: 80.0, c: reverseProgressValue),
                        child: FloatingActionButton(
                          onPressed: onTogglePlay,
                          elevation: 0,
                          focusElevation: 0,
                          hoverElevation: 0,
                          highlightElevation: 0,
                          disabledElevation: 0,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
                          child: AnimatedIcon(
                            progress: playPauseAnim,
                            icon: AnimatedIcons.play_pause,
                            size: rangeProgress(a: 32.0, b: 46.0, c: reverseProgressValue),
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
        if (fastOpacity > 0.0)
          Opacity(
            opacity: fastOpacity,
            child: Transform.translate(
              offset: Offset(0, bottomOffset + (-maxOffset / 4.0 * progressValue)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<Duration>(
                      stream: currentMusic.positionStream,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = currentMusic.duration ?? Duration.zero;
                        final sliderVal = dur.inMilliseconds > 0
                            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0;
                        return Slider(
                          value: sliderVal,
                          onChanged: (v) {
                            if (dur.inMilliseconds > 0) {
                              currentMusic.seek(Duration(milliseconds: (v * dur.inMilliseconds).round()));
                            }
                          },
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: StreamBuilder<Duration>(
                        stream: currentMusic.positionStream,
                        builder: (context, posSnap) {
                          final pos = posSnap.data ?? Duration.zero;
                          final dur = currentMusic.duration ?? Duration.zero;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(pos), style: TextStyle(color: onSecondary)),
                              Text(_formatDuration(dur), style: TextStyle(color: onSecondary)),
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
      ],
    );
  }
}
