import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';

import '../../core/math_utils.dart';
import '../../providers/will_pop_provider.dart';
import '../../providers/current_music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/music/track.dart';
import 'widgets/top_bar.dart';
import 'widgets/track_image.dart';
import 'widgets/track_info.dart';
import 'widgets/player_controls.dart';
import 'widgets/queue_view.dart';
import 'widgets/lyrics_section.dart';
import 'models/animation_data.dart';
import '../../core/haptic_utils.dart';

enum _ActiveGesture { none, vertical, horizontal }

class NowPlaying extends StatefulWidget {
  final AnimationController animation;
  final double bottomInset;
  const NowPlaying({
    super.key,
    required this.animation,
    required this.bottomInset,
  });

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

  // Lyrics Animation
  late AnimationController lyricsAnim;

  // Gesture Locking
  _ActiveGesture _activeGesture = _ActiveGesture.none;
  bool _isReordering = false;
  bool _isFingerDown = false;
  double _startY = 0.0;

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
    queueScrollController.addListener(() {
      if (!queueScrollController.hasClients) return;
      if (!_isFingerDown) return;
      final double scrollOffset = queueScrollController.offset;
      if (scrollOffset < 0 &&
          queueScrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        if (offset >= maxOffset * 2 - 10.0) {
          queueScrollController.jumpTo(0.0);
          _activeGesture = _ActiveGesture.vertical;
          setState(() {
            offset += scrollOffset;
            offset = _applyStagedClamping(
              offset,
              context.read<SettingsProvider>(),
            );
          });
          widget.animation.animateTo(
            offset / maxOffset,
            duration: Duration.zero,
          );
        }
      }
    });
    playPauseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    lyricsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
    final bool firstLoad = offset == 0.0 && prevOffset == 0.0;

    screenSize = MediaQuery.of(context).size;
    maxOffset = screenSize.height;
    sMaxOffset = screenSize.width;
    topInset = MediaQuery.of(context).padding.top;
    bottomInset = widget.bottomInset;

    if (firstLoad) {
      if (widget.animation.value < 0.0) {
        widget.animation.value = 0.0;
      }
      offset = widget.animation.value * maxOffset;
      prevOffset = offset;
    }
  }

  @override
  void dispose() {
    sAnim.dispose();
    queueScrollController.dispose();
    playPauseAnim.dispose();
    lyricsAnim.dispose();
    super.dispose();
  }

  double _applyStagedClamping(double currentOffset, SettingsProvider settings) {
    double lowerBound = -1.1 * headRoom;
    double upperBound = maxOffset * 2;

    if (prevOffset < 10.0 && settings.swipeToDismiss) {
      // Starting from Miniplayer, allow dismissal
      lowerBound = -0.11 * maxOffset;
      upperBound = maxOffset;
    } else if (prevOffset < maxOffset - 10.0) {
      // Locked in Mini/Expanded section
      upperBound = maxOffset;
    } else if (prevOffset > maxOffset + 10.0) {
      // Locked in Expanded/Queue section
      lowerBound = maxOffset;
    }

    return currentOffset.clamp(lowerBound, upperBound);
  }

  PlayerAnimationData _calculateAnimationData(double progressValue) {
    final double clampedProgressValue = progressValue.clamp(0, 1);
    final double inverseProgressValue = 1 - progressValue;
    final double inverseClampedProgressValue = 1 - clampedProgressValue;

    final double reverseProgressValue = inverseAboveOne(progressValue);
    final double reverseClampedProgressValue = reverseProgressValue.clamp(0, 1);

    final double queueProgressValue = progressValue.clamp(1.0, 3.0) - 1.0;
    final double queueClampedProgressValue = queueProgressValue.clamp(0.0, 1.0);

    final double bounceProgressValue = !bounceUp
        ? !bounceDown
              ? reverseProgressValue
              : 1 - (progressValue - 1)
        : progressValue;
    final double bounceClampedProgressValue = bounceProgressValue.clamp(
      0.0,
      1.0,
    );

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

    final double opacity = (bounceClampedProgressValue * 5 - 4).clamp(0, 1);
    final double fastOpacity = (bounceClampedProgressValue * 10 - 9).clamp(
      0,
      1,
    );
    final double topRowOpacity = reverseClampedProgressValue;

    double panelHeight = maxOffset / 1.6;
    if (progressValue > 1.0) {
      panelHeight = rangeProgress(
        a: panelHeight,
        b: maxOffset / 1.6 - 100.0 - topInset,
        c: queueClampedProgressValue,
      );
    }

    return PlayerAnimationData(
      progress: progressValue,
      clampedProgress: clampedProgressValue,
      inverseProgress: inverseProgressValue,
      inverseClampedProgress: inverseClampedProgressValue,
      reverseProgress: reverseProgressValue,
      reverseClampedProgress: reverseClampedProgressValue,
      queueProgress: queueProgressValue,
      queueClampedProgress: queueClampedProgressValue,
      bounceProgress: bounceProgressValue,
      bounceClampedProgress: bounceClampedProgressValue,
      opacity: opacity,
      fastOpacity: fastOpacity,
      topRowOpacity: topRowOpacity,
      bottomOffset: bottomOffset,
      panelHeight: panelHeight,
      borderRadius: borderRadius,
    );
  }

  void togglePlay() {
    final settings = context.read<SettingsProvider>();
    final currentMusic = context.read<CurrentMusicProvider>();
    if (currentMusic.isPlaying) {
      currentMusic.pause();
    } else {
      currentMusic.play();
    }
    HapticUtils.trigger(settings);
  }

  void toggleLyrics() {
    if (lyricsAnim.value > 0.5) {
      lyricsAnim.animateBack(0.0, curve: bouncingCurve);
    } else {
      lyricsAnim.animateTo(1.0, curve: bouncingCurve);
    }
  }

  // --- Vertical Snapping ---
  void verticalSnapping() {
    final distance = prevOffset - offset;
    final speed = velocity.getVelocity().pixelsPerSecond.dy;
    const threshold = 500.0;

    // Staged Snapping: Lock animations in each section
    if (prevOffset > maxOffset + 100.0) {
      // Started in Queue section [1, 2], can only snap back to Expanded or stay in Queue
      if ((speed > threshold && distance > 10) || distance > actuationOffset) {
        snapToExpanded();
      } else {
        snapToQueue();
      }
    } else if (prevOffset < maxOffset - 100.0) {
      // Started in Mini/Expanded section [0, 1]
      if (-speed > threshold || -distance > actuationOffset) {
        snapToExpanded();
      } else if (context.read<SettingsProvider>().swipeToDismiss &&
          offset < -actuationOffset / 2) {
        // Swiped down from Miniplayer far enough
        snapToDismissed();
      } else {
        snapToMini();
      }
    } else {
      // Started at Expanded (threshold allows for small variances)
      // Can go to Mini (Down) or Queue (Up)
      if (speed > threshold || distance > actuationOffset) {
        snapToMini();
      } else if (-speed > threshold || -distance > actuationOffset) {
        snapToQueue();
      } else {
        snapToExpanded();
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

  void snapToDismissed({bool haptic = true}) {
    offset = -0.1 * maxOffset;
    final settings = context.read<SettingsProvider>();
    widget.animation
        .animateTo(
          -0.1,
          curve: bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          if (mounted) {
            if (haptic) {
              HapticUtils.trigger(settings, force: HapticForce.heavy);
            }
            context.read<CurrentMusicProvider>().stop();
          }
        });
  }

  void snap({bool haptic = true}) {
    final settings = context.read<SettingsProvider>();
    widget.animation
        .animateTo(
          offset / maxOffset,
          curve: bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          if (mounted) {
            if (haptic) {
              HapticUtils.trigger(settings);
            }
            bounceUp = false;
          }
        });
  }

  // --- Horizontal Snapping ---
  void snapToPrev() {
    sOffset = -sMaxOffset;
    final settings = context.read<SettingsProvider>();
    sAnim
        .animateTo(
          -1.0,
          curve: bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          if (mounted) {
            final currentMusic = context.read<CurrentMusicProvider>();
            final oldTrackId = currentMusic.currentTrack?.id;

            sOffset = 0;
            sAnim.animateTo(0.0, duration: Duration.zero);
            currentMusic.playPrevious();

            // Only vibrate if track changed
            if (currentMusic.currentTrack?.id != oldTrackId) {
              HapticUtils.trigger(settings);
            }
          }
        });
  }

  void snapToCurrent() {
    sOffset = 0;
    sAnim.animateTo(
      0.0,
      curve: bouncingCurve,
      duration: const Duration(milliseconds: 300),
    );
  }

  void snapToNext() {
    sOffset = sMaxOffset;
    final settings = context.read<SettingsProvider>();
    sAnim
        .animateTo(
          1.0,
          curve: bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          if (mounted) {
            final currentMusic = context.read<CurrentMusicProvider>();
            final oldTrackId = currentMusic.currentTrack?.id;

            sOffset = 0;
            sAnim.animateTo(0.0, duration: Duration.zero);
            currentMusic.playNext();

            // Only vibrate if track changed
            if (currentMusic.currentTrack?.id != oldTrackId) {
              HapticUtils.trigger(settings);
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final track = context.select<CurrentMusicProvider, Track?>(
      (p) => p.currentTrack,
    );
    final showMiniplayerShadow = context.select<SettingsProvider, bool>(
      (s) => s.showMiniplayerShadow,
    );
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
          _isFingerDown = true;
          if (_isReordering) return;
          if (event.position.dy > screenSize.height - deadSpace) return;
          _startY = event.position.dy;
          _activeGesture = _ActiveGesture.none;
          velocity.addPosition(event.timeStamp, event.position);
          prevOffset = offset;
          bounceUp = false;
          bounceDown = false;
        },
        onPointerMove: (event) {
          if (event.position.dy > screenSize.height - deadSpace) return;
          if (_activeGesture == _ActiveGesture.horizontal || _isReordering) {
            return;
          }

          velocity.addPosition(event.timeStamp, event.position);

          final settings = context.read<SettingsProvider>();
          final dy = event.delta.dy.abs();
          final dx = event.delta.dx.abs();

          if (_activeGesture == _ActiveGesture.none) {
            if (dy > dx && dy > 2) {
              // If Queue is open, ONLY become vertical if touch is on the handle
              if (offset >= maxOffset - 10.0) {
                final bool isHandle = event.position.dy < topInset + 160.0;
                if (!isHandle) return;
              }
              _activeGesture = _ActiveGesture.vertical;
            } else if (dx > dy && dx > 2) {
              _activeGesture = _ActiveGesture.horizontal;
              return;
            } else {
              return;
            }
          }
          final deltaY = event.delta.dy;
          final isUp = deltaY < 0;
          final isDown = deltaY > 0;

          // --- Gesture Priority Logic ---
          if (offset >= maxOffset - 10.0) {
            // In Queue State
            final bool isAtTop =
                offset < (maxOffset * 2 - 10.0) ||
                !queueScrollController.hasClients ||
                queueScrollController.offset <= 0;
            final bool isHandle = event.position.dy < topInset + 160.0;

            if (!isHandle) {
              if (isUp && offset >= maxOffset * 2 - 1) {
                // Fully open and dragging up: Let list scroll
                return;
              }
              if (isDown) {
                if (!isAtTop) return;

                // Threshold: Must have pulled down at least 20px since gesture start
                // to trigger drawer closure from the list area.
                final totalDy = event.position.dy - _startY;
                if (totalDy < 20.0) return;
              }
            }
          }
          // ------------------------------

          offset -= deltaY;
          offset = _applyStagedClamping(offset, settings);
          widget.animation.animateTo(
            offset / maxOffset,
            duration: Duration.zero,
          );
        },
        onPointerUp: (event) {
          _isFingerDown = false;
          if (_isReordering) return;
          if (_activeGesture == _ActiveGesture.vertical) {
            verticalSnapping();
          }
          _activeGesture = _ActiveGesture.none;
        },
        onPointerCancel: (event) {
          _isFingerDown = false;
          if (_isReordering) return;
          if (_activeGesture == _ActiveGesture.vertical) {
            verticalSnapping();
          }
          _activeGesture = _ActiveGesture.none;
        },
        child: GestureDetector(
          onTap: () {
            if (widget.animation.value < (actuationOffset / maxOffset)) {
              snapToExpanded();
            }
          },
          onVerticalDragUpdate: (details) {
            if (_activeGesture == _ActiveGesture.horizontal || _isReordering) {
              return;
            }
            if (details.globalPosition.dy > screenSize.height - deadSpace) {
              return;
            }
            if (_activeGesture == _ActiveGesture.none) {
              _activeGesture = _ActiveGesture.vertical;
            }
            final settings = context.read<SettingsProvider>();
            final deltaY = details.primaryDelta ?? 0;
            final isUp = deltaY < 0;
            final isDown = deltaY > 0;

            // --- Gesture Priority Logic ---
            if (offset >= maxOffset - 10.0) {
              final bool isAtTop =
                  offset < (maxOffset * 2 - 10.0) ||
                  !queueScrollController.hasClients ||
                  queueScrollController.offset <= 0;
              final bool isHandle =
                  details.globalPosition.dy < topInset + 160.0;

              if (!isHandle) {
                if (isUp && offset >= maxOffset * 2 - 1) return;
                if (isDown && !isAtTop) return;
              }
            }
            // ------------------------------

            offset -= deltaY;
            offset = _applyStagedClamping(offset, settings);
            widget.animation.animateTo(
              offset / maxOffset,
              duration: Duration.zero,
            );
          },
          onVerticalDragEnd: (_) {
            _activeGesture = _ActiveGesture.none;
            verticalSnapping();
          },
          onHorizontalDragStart: (details) {
            if (offset > maxOffset) return;
            if (_activeGesture == _ActiveGesture.vertical) return;
            if (!context.read<SettingsProvider>().swipeToChangeTrack) return;
            _activeGesture = _ActiveGesture.horizontal;
            sPrevOffset = sOffset;
          },
          onHorizontalDragUpdate: (details) {
            if (offset > maxOffset) return;
            final settings = context.read<SettingsProvider>();
            if (!settings.swipeToChangeTrack) return;
            if (_activeGesture == _ActiveGesture.vertical) return;
            if (details.globalPosition.dy > screenSize.height - deadSpace) {
              return;
            }

            final currentMusic = context.read<CurrentMusicProvider>();
            final playlist = currentMusic.currentPlaylist;
            final track = currentMusic.currentTrack;

            bool canNext = false;
            bool canPrev = false;

            if (playlist != null && track != null) {
              final index = playlist.tracks.indexOf(track);
              canNext =
                  index < playlist.tracks.length - 1 ||
                  currentMusic.isRepeatEnabled ||
                  settings.autoPlay;
              canPrev = index > 0 || currentMusic.isRepeatEnabled;
            }

            double delta = details.primaryDelta ?? 0.0;
            sOffset -= delta;

            // Clamping logic:
            // sOffset > 0 is Swipe Left (Next)
            // sOffset < 0 is Swipe Right (Prev)
            double minClamp = canPrev ? -sMaxOffset : 0.0;
            double maxClamp = canNext ? sMaxOffset : 0.0;

            sOffset = sOffset.clamp(minClamp, maxClamp);
            sAnim.animateTo(sOffset / sMaxOffset, duration: Duration.zero);
          },
          onHorizontalDragEnd: (details) {
            if (offset > maxOffset) return;
            _activeGesture = _ActiveGesture.none;
            final settings = context.read<SettingsProvider>();
            if (!settings.swipeToChangeTrack) return;

            final currentMusic = context.read<CurrentMusicProvider>();
            final playlist = currentMusic.currentPlaylist;
            final track = currentMusic.currentTrack;

            bool canNext = false;
            bool canPrev = false;

            if (playlist != null && track != null) {
              final index = playlist.tracks.indexOf(track);
              canNext =
                  index < playlist.tracks.length - 1 ||
                  currentMusic.isRepeatEnabled ||
                  settings.autoPlay;
              canPrev = index > 0 || currentMusic.isRepeatEnabled;
            }

            final distance = sPrevOffset - sOffset;
            final speed = velocity.getVelocity().pixelsPerSecond.dx;
            const threshold = 1000.0;

            if (canPrev &&
                (speed > threshold ||
                    distance > actuationOffset * sActuationMulti)) {
              snapToPrev();
            } else if (canNext &&
                (-speed > threshold ||
                    -distance > actuationOffset * sActuationMulti)) {
              snapToNext();
            } else {
              snapToCurrent();
            }
          },
          child: AnimatedBuilder(
            animation: widget.animation,
            builder: (context, child) {
              final data = _calculateAnimationData(widget.animation.value);

              return Stack(
                children: [
                  // Background component of the player
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: Offset(0, data.bottomOffset),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              12 *
                              (1 - data.clampedProgress * 10 + 9).clamp(0, 1),
                          vertical: 12 * data.inverseClampedProgress,
                        ),
                        child: Container(
                          height: rangeProgress(
                            a: 82.0,
                            b: data.panelHeight,
                            c: data.progress.clamp(0, 3),
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: data.borderRadius,
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: showMiniplayerShadow
                                ? [
                                    BoxShadow(
                                      color:
                                          (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.black.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.08,
                                                    ))
                                              .withValues(
                                                alpha:
                                                    (Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? 0.2
                                                        : 0.08) *
                                                    data.inverseClampedProgress,
                                              ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Horizontal top bar
                  if (data.topRowOpacity > 0.0)
                    TopBar(
                      topRowOpacity: data.topRowOpacity,
                      bounceProgressValue: data.bounceProgress,
                      onSecondary: onSecondary,
                      onSnapToMini: snapToMini,
                    ),
                  // Lyrics button
                  // if (data.opacity > 0.0)
                  //   Material(
                  //     type: MaterialType.transparency,
                  //     child: Opacity(
                  //       opacity: data.opacity,
                  //       child: Transform.translate(
                  //         offset: Offset(-50, -100 * data.inverseProgress),
                  //         child: Align(
                  //           alignment: Alignment.bottomRight,
                  //           child: SafeArea(
                  //             child: Padding(
                  //               padding: const EdgeInsets.symmetric(
                  //                 horizontal: 24.0,
                  //                 vertical: 12.0,
                  //               ),
                  //               child: IconButton(
                  //                 onPressed: null, // TODO: lyrics
                  //                 icon: const Icon(
                  //                   FlutterRemix.chat_quote_line,
                  //                 ),
                  //                 color: colorScheme.onSurface,
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // Queue access button
                  AnimatedBuilder(
                    animation: lyricsAnim,
                    builder: (context, child) {
                      return Offstage(
                        offstage: data.opacity == 0.0,
                        child: Material(
                          type: MaterialType.transparency,
                          child: Opacity(
                            opacity: (data.opacity * (1 - lyricsAnim.value))
                                .clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                -100 * data.inverseProgress +
                                    (100 * lyricsAnim.value),
                              ),
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
                                      icon: const Icon(
                                        FlutterRemix.play_list_line,
                                        size: 24.0,
                                      ),
                                      color: onSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: lyricsAnim,
                    builder: (context, _) {
                      return LyricsSection(
                        lyricsAnim: lyricsAnim,
                        data: data,
                        maxOffset: maxOffset,
                        topInset: topInset,
                        track: track,
                      );
                    },
                  ),
                  TrackInfo(
                    sAnim: sAnim,
                    sMaxOffset: sMaxOffset,
                    stParallax: stParallax,
                    maxOffset: maxOffset,
                    topInset: topInset,
                    bounceUp: bounceUp,
                    bounceDown: bounceDown,
                    screenSize: screenSize,
                    data: data,
                    lyricsAnim: lyricsAnim,
                    onToggleLyrics: toggleLyrics,
                  ),
                  TrackImage(
                    sAnim: sAnim,
                    sMaxOffset: sMaxOffset,
                    siParallax: siParallax,
                    bounceUp: bounceUp,
                    maxOffset: maxOffset,
                    topInset: topInset,
                    bounceDown: bounceDown,
                    screenSize: screenSize,
                    data: data,
                    lyricsAnim: lyricsAnim,
                  ),
                  PlayerControls(
                    maxOffset: maxOffset,
                    topInset: topInset,
                    bounceUp: bounceUp,
                    bounceDown: bounceDown,
                    onSecondary: onSecondary,
                    screenSize: screenSize,
                    onTogglePlay: togglePlay,
                    playPauseAnim: playPauseAnim,
                    data: data,
                    lyricsAnim: lyricsAnim,
                  ),
                  QueueView(
                    queueProgressValue: data.queueProgress,
                    maxOffset: maxOffset,
                    topInset: topInset,
                    controller: queueScrollController,
                    onReorderBegin: () {
                      if (!_isReordering) {
                        setState(() => _isReordering = true);
                      }
                    },
                    onReorderEnd: () {
                      if (_isReordering) {
                        setState(() => _isReordering = false);
                      }
                    },
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
