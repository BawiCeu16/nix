import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nix/core/format.dart';
import 'package:provider/provider.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:m3e_seekbar/m3e_seekbar.dart';
import 'package:nix/core/math_utils.dart';
import 'package:nix/ui/miniplayer/models/animation_data.dart';

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
  final Animation<double> lyricsAnim;

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
    required this.lyricsAnim,
  });

  @override
  Widget build(BuildContext context) {
    final duration = context.select<CurrentMusicProvider, Duration?>(
      (p) => p.duration,
    );
    final currentMusic = context.read<CurrentMusicProvider>();

    return AnimatedBuilder(
      animation: lyricsAnim,
      builder: (context, child) {
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
                              : 0.0)) +
                      (90.0 * lyricsAnim.value * data.bounceClampedProgress),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // IconButton(
                                  //   iconSize: 28.0,
                                  //   icon: Icon(
                                  //     FlutterRemix.shuffle_line,
                                  //     color: isShuffleEnabled
                                  //         ? Theme.of(
                                  //             context,
                                  //           ).colorScheme.primary
                                  //         : onSecondary,
                                  //   ),
                                  //   onPressed: () =>
                                  //       currentMusic.toggleShuffle(),
                                  // ),
                                  // IconButton(
                                  //   iconSize: 28.0,
                                  //   icon: Icon(
                                  //     isRepeatEnabled
                                  //         ? FlutterRemix.repeat_one_line
                                  //         : FlutterRemix.repeat_2_line,
                                  //     color: isRepeatEnabled
                                  //         ? Theme.of(
                                  //             context,
                                  //           ).colorScheme.primary
                                  //         : onSecondary,
                                  //   ),
                                  //   onPressed: () =>
                                  //       currentMusic.toggleRepeat(),
                                  // ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    iconSize: 36.0,
                                    icon: Icon(
                                      FlutterRemix.skip_back_fill,
                                      color: onSecondary,
                                    ),
                                    onPressed: () =>
                                        currentMusic.playPrevious(),
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
                                            80 *
                                                data.bounceClampedProgress /
                                                2 +
                                            (data.queueProgress * 24.0),
                                ),
                              ),
                          child: SizedBox(
                            height: rangeProgress(
                              a: 60.0,
                              b: 80.0 - (10.0 * lyricsAnim.value),
                              c: data.reverseProgress,
                            ),
                            width: rangeProgress(
                              a: 60.0,
                              b: 80.0 - (10.0 * lyricsAnim.value),
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
                                  b: 46.0 - (5.0 * lyricsAnim.value),
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
                    data.bottomOffset +
                        (-maxOffset / 4.3 * data.progress) +
                        (105.0 * lyricsAnim.value * data.bounceClampedProgress),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: _PlayerSlider(
                        currentMusic: currentMusic,
                        duration: duration,
                        onSecondary: onSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlayerSlider extends StatefulWidget {
  final CurrentMusicProvider currentMusic;
  final Duration? duration;
  final Color onSecondary;

  const _PlayerSlider({
    required this.currentMusic,
    required this.duration,
    required this.onSecondary,
  });

  @override
  State<_PlayerSlider> createState() => _PlayerSliderState();
}

class _PlayerSliderState extends State<_PlayerSlider> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  DateTime? _lastSeekTime;
  Timer? _dragEndTimer;

  void _onSliderChangeStart(double v) {
    HapticFeedback.selectionClick();
    setState(() {
      _isDragging = true;
      _dragValue = v;
    });
  }

  void _onSliderChanged(double v, Duration dur) {
    setState(() {
      _isDragging = true;
      _dragValue = v;
    });

    final now = DateTime.now();
    if (_lastSeekTime == null ||
        now.difference(_lastSeekTime!) > const Duration(milliseconds: 100)) {
      _lastSeekTime = now;
      if (dur.inMilliseconds > 0) {
        widget.currentMusic.seek(
          Duration(milliseconds: (v * dur.inMilliseconds).round()),
        );
      }
    }
  }

  void _onSliderChangeEnd(double v, Duration dur) {
    if (dur.inMilliseconds > 0) {
      widget.currentMusic.seek(
        Duration(milliseconds: (v * dur.inMilliseconds).round()),
      );
    }
    _dragEndTimer?.cancel();
    _dragEndTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isDragging = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _dragEndTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: widget.currentMusic.playerStateStream,
      builder: (context, stateSnap) {
        final isPlaying = stateSnap.data?.playing ?? false;

        return StreamBuilder<Duration>(
          stream: widget.currentMusic.positionStream,
          builder: (context, posSnap) {
            final realPos = posSnap.data ?? Duration.zero;
            final dur = widget.duration ?? Duration.zero;
            final double realVal = dur.inMilliseconds > 0
                ? (realPos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;

            final targetVal = _isDragging ? _dragValue : realVal;
            final displayPos = _isDragging
                ? Duration(
                    milliseconds: (targetVal * dur.inMilliseconds).round(),
                  )
                : realPos;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: targetVal, end: targetVal),
                  duration: _isDragging || !isPlaying
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  curve: Curves.linear,
                  builder: (context, animVal, child) {
                    return M3EWavySeekbar(
                      value: animVal.clamp(0.0, 1.0),
                      isPlaying: isPlaying,
                      handleShape: M3ESeekbarHandleShape.rectangle,
                      handleHeight: 18,
                      lineAmplitude: 2.5,
                      waveLength: 22.0,
                      activeColor: Theme.of(context).colorScheme.primary,
                      thumbColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .3),
                      strokeWidth: 2.8,
                      onChangeStart: _onSliderChangeStart,
                      onChanged: (v) => _onSliderChanged(v, dur),
                      onChangeEnd: (v) => _onSliderChangeEnd(v, dur),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayPos.shortFormat(),
                        style: TextStyle(color: widget.onSecondary),
                      ),
                      Text(
                        dur.shortFormat(),
                        style: TextStyle(color: widget.onSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
