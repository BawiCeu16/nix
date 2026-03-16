import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/math_utils.dart';
import '../../providers/will_pop_provider.dart';
import '../../providers/current_music_provider.dart';
import 'widgets/top_bar.dart';
import 'widgets/track_image.dart';
import 'widgets/track_info.dart';
import 'widgets/player_controls.dart';
import 'widgets/queue_view.dart';

class NowPlaying extends StatefulWidget {
  final AnimationController animation;
  const NowPlaying({super.key, required this.animation});

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> with TickerProviderStateMixin {
  // Vertical Physics
  double offset = 0.0;
  double prevOffset = 0.0;
  late Size screenSize;
  late double maxOffset;
  late double topInset;
  late double bottomInset;
  final velocity = VelocityTracker.withKind(PointerDeviceKind.touch);

  static const Cubic bouncingCurve = Cubic(0.175, 0.885, 0.50, 1.0);
  static const headRoom = 50.0;
  static const actuationOffset = 100.0;
  static const deadSpace = 100.0;

  bool bounceUp = false;
  bool bounceDown = false;

  // Horizontal Physics (Track Swiping)
  double sOffset = 0.0;
  double sPrevOffset = 0.0;
  double stParallax = 1.0;
  double siParallax = 1.15;
  static const sActuationMulti = 1.5;
  late double sMaxOffset;
  late AnimationController sAnim;

  // Queue View Controller
  late ScrollController queueScrollController;

  // Playback Animation
  late AnimationController playPauseAnim;

  @override
  void initState() {
    super.initState();
    sAnim = AnimationController(
      vsync: this,
      lowerBound: -1,
      upperBound: 1,
      value: 0.0,
    );
    queueScrollController = ScrollController();
    playPauseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Listen to actual player state in next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentMusic = context.read<CurrentMusicProvider>();
      currentMusic.isPlayingStream.listen((playing) {
        if (!mounted) return;
        if (playing) {
          playPauseAnim.forward();
        } else {
          playPauseAnim.reverse();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenSize = MediaQuery.of(context).size;
    maxOffset = screenSize.height;
    sMaxOffset = screenSize.width;
    topInset = MediaQuery.of(context).padding.top;
    bottomInset = MediaQuery.of(context).padding.bottom;
  }

  @override
  void dispose() {
    sAnim.dispose();
    queueScrollController.dispose();
    playPauseAnim.dispose();
    super.dispose();
  }

  void togglePlay() {
    final currentMusic = context.read<CurrentMusicProvider>();
    if (currentMusic.isPlaying) {
      currentMusic.pause();
    } else {
      currentMusic.play();
    }
  }

  // --- Vertical Snapping ---
  void verticalSnapping() {
    final distance = prevOffset - offset;
    final speed = velocity.getVelocity().pixelsPerSecond.dy;
    const threshold = 500.0;

    if (prevOffset > maxOffset) {
      if (speed > threshold || distance > actuationOffset) {
        snapToExpanded();
      } else {
        snapToQueue();
      }
    } else if (prevOffset > maxOffset / 2) {
      if (speed > threshold || distance > actuationOffset) {
        snapToMini();
      } else if (-speed > threshold || -distance > actuationOffset) {
        snapToQueue();
      } else {
        snapToExpanded();
      }
    } else {
      if (-speed > threshold || -distance > actuationOffset) {
        snapToExpanded();
      } else {
        snapToMini();
      }
    }
  }

  void snapToExpanded({bool haptic = true}) {
    offset = maxOffset;
    if (prevOffset < maxOffset) bounceUp = true;
    if (prevOffset > maxOffset) bounceDown = true;
    snap(haptic: haptic);
  }

  void snapToMini({bool haptic = true}) {
    offset = 0;
    bounceDown = false;
    snap(haptic: haptic);
  }

  void snapToQueue({bool haptic = true}) {
    offset = maxOffset * 2;
    bounceUp = false;
    snap(haptic: haptic);
  }

  void snap({bool haptic = true}) {
    if (haptic) HapticFeedback.mediumImpact();
    widget.animation
        .animateTo(
          offset / maxOffset,
          curve: bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          bounceUp = false;
        });
  }

  // --- Horizontal Snapping ---
  void snapToPrev() {
    HapticFeedback.mediumImpact();
    sOffset = -sMaxOffset;
    sAnim
        .animateTo(
          -1.0,
          curve: bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          sOffset = 0;
          sAnim.animateTo(0.0, duration: Duration.zero);
        });
  }

  void snapToCurrent() {
    HapticFeedback.mediumImpact();
    sOffset = 0;
    sAnim.animateTo(
      0.0,
      curve: bouncingCurve,
      duration: const Duration(milliseconds: 300),
    );
  }

  void snapToNext() {
    HapticFeedback.mediumImpact();
    sOffset = sMaxOffset;
    sAnim
        .animateTo(
          1.0,
          curve: bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          sOffset = 0;
          sAnim.animateTo(0.0, duration: Duration.zero);
        });
  }

  @override
  Widget build(BuildContext context) {
    final Color onSecondary = Theme.of(
      context,
    ).colorScheme.onSecondaryContainer;

    // --- CONSUMER & POPPER REGISTRATION ADDED HERE ---
    return Consumer<WillPopProvider>(
      builder: (context, willPop, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          willPop.registerPopper(() {
            if (offset > maxOffset) {
              snapToExpanded(haptic: false);
              return false; // Prevent app closing
            }
            if (offset > maxOffset / 2) {
              snapToMini(haptic: true);
              return false; // Prevent app closing
            }
            return true; // Let app close normally
          });
        });
        return child!;
      },
      child: Listener(
        onPointerDown: (event) {
          if (event.position.dy > screenSize.height - deadSpace) return;
          velocity.addPosition(event.timeStamp, event.position);
          prevOffset = offset;
          bounceUp = false;
          bounceDown = false;
        },
        onPointerMove: (event) {
          if (event.position.dy > screenSize.height - deadSpace) return;
          velocity.addPosition(event.timeStamp, event.position);

          offset -= event.delta.dy;
          offset = offset.clamp(-headRoom, maxOffset * 2);
          widget.animation.animateTo(
            offset / maxOffset,
            duration: Duration.zero,
          );
        },
        onPointerUp: (event) => verticalSnapping(),
        child: GestureDetector(
          onTap: () {
            if (widget.animation.value < (actuationOffset / maxOffset)) {
              snapToExpanded();
            }
          },
          onVerticalDragUpdate: (details) {
            if (details.globalPosition.dy > screenSize.height - deadSpace) {
              return;
            }
            offset -= details.primaryDelta ?? 0;
            offset = offset.clamp(-headRoom, maxOffset * 2 + headRoom / 2);
            widget.animation.animateTo(
              offset / maxOffset,
              duration: Duration.zero,
            );
          },
          onVerticalDragEnd: (_) => verticalSnapping(),
          onHorizontalDragStart: (details) {
            if (offset > maxOffset) return;
            sPrevOffset = sOffset;
          },
          onHorizontalDragUpdate: (details) {
            if (offset > maxOffset) return;
            if (details.globalPosition.dy > screenSize.height - deadSpace) {
              return;
            }
            sOffset -= details.primaryDelta ?? 0.0;
            sOffset = sOffset.clamp(-sMaxOffset, sMaxOffset);
            sAnim.animateTo(sOffset / sMaxOffset, duration: Duration.zero);
          },
          onHorizontalDragEnd: (details) {
            if (offset > maxOffset) return;
            final distance = sPrevOffset - sOffset;
            final speed = velocity.getVelocity().pixelsPerSecond.dx;
            const threshold = 1000.0;

            if (speed > threshold ||
                distance > actuationOffset * sActuationMulti) {
              snapToPrev();
            } else if (-speed > threshold ||
                -distance > actuationOffset * sActuationMulti) {
              snapToNext();
            } else {
              snapToCurrent();
            }
          },
          child: AnimatedBuilder(
            animation: widget.animation,
            builder: (context, child) {
              final double progressValue = widget.animation.value;
              final double clampedProgressValue = progressValue.clamp(0, 1);
              final double inverseProgressValue = 1 - progressValue;
              final double inverseClampedProgressValue =
                  1 - clampedProgressValue;

              final double reverseProgressValue = inverseAboveOne(
                progressValue,
              );
              final double reverseClampedProgressValue = reverseProgressValue
                  .clamp(0, 1);

              final double queueProgressValue =
                  progressValue.clamp(1.0, 3.0) - 1.0;
              final double queueClampedProgressValue = queueProgressValue.clamp(
                0.0,
                1.0,
              );

              final double bounceProgressValue = !bounceUp
                  ? !bounceDown
                        ? reverseProgressValue
                        : 1 - (progressValue - 1)
                  : progressValue;
              final double bounceClampedProgressValue = bounceProgressValue
                  .clamp(0.0, 1.0);

              final BorderRadius borderRadius = BorderRadius.only(
                topLeft: Radius.circular(20.0 + 6.0 * progressValue),
                topRight: Radius.circular(20.0 + 6.0 * progressValue),
                bottomLeft: Radius.circular(
                  20.0 * (1 - progressValue * 10 + 9).clamp(0, 1),
                ),
                bottomRight: Radius.circular(
                  20.0 * (1 - progressValue * 10 + 9).clamp(0, 1),
                ),
              );

              final double bottomOffset =
                  (-80 * inverseClampedProgressValue +
                      progressValue.clamp(-1, 0) * -200) -
                  (bottomInset * inverseClampedProgressValue);

              final double opacity = (bounceClampedProgressValue * 5 - 4).clamp(
                0,
                1,
              );
              final double fastOpacity = (bounceClampedProgressValue * 10 - 9)
                  .clamp(0, 1);
              final double topRowOpacity = reverseClampedProgressValue;

              double panelHeight = maxOffset / 1.6;
              if (progressValue > 1.0) {
                panelHeight = rangeProgress(
                  a: panelHeight,
                  b: maxOffset / 1.6 - 100.0 - topInset,
                  c: queueClampedProgressValue,
                );
              }

              return Stack(
                children: [
                  //This is the background of the mini player
                  Container(
                    color: progressValue > 0 ? Colors.transparent : null,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        offset: Offset(0, bottomOffset),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                12 *
                                (1 - clampedProgressValue * 10 + 9).clamp(0, 1),
                            vertical: 12 * inverseClampedProgressValue,
                          ),
                          child: Container(
                            height: rangeProgress(
                              a: 82.0,
                              b: panelHeight,
                              c: progressValue.clamp(0, 3),
                            ),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: borderRadius,
                              boxShadow: [
                                // BoxShadow(
                                //   color: clampedProgressValue > 0
                                //       ? Theme.of(context).colorScheme.onSurface
                                //             .withValues(alpha: .1)
                                //       : Colors.black12,
                                //   blurRadius: 7,
                                //   offset: Offset(0, 0),
                                // ),
                              ],
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  //This is the top bar
                  if (topRowOpacity > 0.0)
                    TopBar(
                      topRowOpacity: topRowOpacity,
                      bounceProgressValue: bounceProgressValue,
                      onSecondary: onSecondary,
                      onSnapToMini: snapToMini,
                    ),
                  //This is the lyrics button
                  if (opacity > 0.0)
                    Material(
                      type: MaterialType.transparency,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(-50, -100 * inverseProgressValue),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 12.0,
                                ),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    FlutterRemix.chat_quote_line,
                                    size: 28.0,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  //This is the queue button
                  Offstage(
                    offstage: opacity == 0.0,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, -100 * inverseProgressValue),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 14.0,
                                ),
                                child: IconButton(
                                  onPressed: snapToQueue,
                                  icon: Icon(
                                    FlutterRemix.play_list_line,
                                    size: 24.0,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  //This is the track info
                  TrackInfo(
                    sAnim: sAnim,
                    sMaxOffset: sMaxOffset,
                    stParallax: stParallax,
                    queueProgressValue: queueProgressValue,
                    maxOffset: maxOffset,
                    topInset: topInset,
                    bounceUp: bounceUp,
                    bounceDown: bounceDown,
                    bounceProgressValue: bounceProgressValue,
                    bottomOffset: bottomOffset,
                    bounceClampedProgressValue: bounceClampedProgressValue,
                    screenSize: screenSize,
                  ),
                  //This is the track image
                  TrackImage(
                    sAnim: sAnim,
                    sMaxOffset: sMaxOffset,
                    siParallax: siParallax,
                    bounceUp: bounceUp,
                    maxOffset: maxOffset,
                    topInset: topInset,
                    bounceDown: bounceDown,
                    queueProgressValue: queueProgressValue,
                    bounceProgressValue: bounceProgressValue,
                    bottomOffset: bottomOffset,
                    bounceClampedProgressValue: bounceClampedProgressValue,
                    screenSize: screenSize,
                  ),
                  //This is the player controls
                  PlayerControls(
                    bottomOffset: bottomOffset,
                    maxOffset: maxOffset,
                    bounceProgressValue: bounceProgressValue,
                    topInset: topInset,
                    bounceUp: bounceUp,
                    bounceDown: bounceDown,
                    queueProgressValue: queueProgressValue,
                    inverseClampedProgressValue: inverseClampedProgressValue,
                    fastOpacity: fastOpacity,
                    onSecondary: onSecondary,
                    reverseClampedProgressValue: reverseClampedProgressValue,
                    clampedProgressValue: clampedProgressValue,
                    screenSize: screenSize,
                    reverseProgressValue: reverseProgressValue,
                    onTogglePlay: togglePlay,
                    playPauseAnim: playPauseAnim,
                    progressValue: progressValue,
                    bounceClampedProgressValue: bounceClampedProgressValue,
                  ),
                  //This is the queue view
                  QueueView(
                    queueProgressValue: queueProgressValue,
                    maxOffset: maxOffset,
                    topInset: topInset,
                    controller: queueScrollController,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
