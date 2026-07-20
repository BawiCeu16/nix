import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';

import 'package:nix/core/math_utils.dart';
import 'package:nix/core/haptic_utils.dart';
import 'package:nix/providers/will_pop_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/miniplayer/models/animation_data.dart';

/// Active gesture mode for gesture locking.
enum ActiveGesture { none, vertical, horizontal }

/// Calculates animation values, thresholds, and physics curves for the NowPlaying sheet.
class NowPlayingPhysics {
  static const Cubic bouncingCurve = Cubic(0.175, 1.195, 0.80, 1.0);
  static const double headRoom = 50.0;
  static const double actuationOffset = 100.0;
  static const double deadSpace = 100.0;
  static const double sActuationMulti = 1.5;

  /// Applies staged offset clamping based on active sheet position and user settings.
  static double applyStagedClamping({
    required double currentOffset,
    required double prevOffset,
    required double maxOffset,
    required SettingsProvider settings,
  }) {
    double lowerBound = -1.1 * headRoom;
    double upperBound = maxOffset * 2;

    if (prevOffset < 10.0 && settings.swipeToDismiss) {
      lowerBound = -0.11 * maxOffset;
      upperBound = maxOffset;
    } else if (prevOffset < maxOffset - 10.0) {
      upperBound = maxOffset;
    } else if (prevOffset > maxOffset + 10.0) {
      lowerBound = maxOffset;
    }

    return currentOffset.clamp(lowerBound, upperBound);
  }

  /// Transforms raw progress value into fully computed [PlayerAnimationData].
  static PlayerAnimationData calculateAnimationData({
    required double progressValue,
    required double maxOffset,
    required double topInset,
    required double bottomInset,
    required bool bounceUp,
    required bool bounceDown,
  }) {
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
}

/// Controller managing all physics, gesture locks, animation controllers, and state calculations for the NowPlaying sheet.
class NowPlayingController with ChangeNotifier {
  // Vertical Physics State
  double offset = 0.0;
  double prevOffset = 0.0;
  late Size screenSize;
  late double maxOffset;
  late double topInset;
  late double bottomInset;
  final velocity = VelocityTracker.withKind(PointerDeviceKind.touch);

  bool bounceUp = false;
  bool bounceDown = false;

  // Horizontal Physics (Track Swiping) State
  double sOffset = 0.0;
  double sPrevOffset = 0.0;
  double stParallax = 1.0;
  double siParallax = 1.15;
  late double sMaxOffset;
  late AnimationController sAnim;

  // Queue View Scroll Controller
  late ScrollController queueScrollController;

  // Playback & Lyrics Animation Controllers
  late AnimationController playPauseAnim;
  late AnimationController lyricsAnim;

  // Gesture Locking & Drag State
  ActiveGesture activeGesture = ActiveGesture.none;
  bool isReordering = false;
  bool isFingerDown = false;
  double startY = 0.0;

  late AnimationController _sheetAnimation;
  StreamSubscription<bool>? _playingStreamSub;

  /// Initializes animation controllers, scroll listeners, and poppers.
  void init({
    required TickerProvider vsync,
    required AnimationController sheetAnimation,
    required BuildContext context,
  }) {
    _sheetAnimation = sheetAnimation;

    sAnim = AnimationController(
      vsync: vsync,
      lowerBound: -1,
      upperBound: 1,
      value: 0.0,
    );

    queueScrollController = ScrollController();
    queueScrollController.addListener(() {
      if (!queueScrollController.hasClients) return;
      if (!isFingerDown) return;
      final double scrollOffset = queueScrollController.offset;
      if (scrollOffset < 0 &&
          queueScrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        if (offset >= maxOffset * 2 - 10.0) {
          queueScrollController.jumpTo(0.0);
          activeGesture = ActiveGesture.vertical;
          offset += scrollOffset;
          offset = applyStagedClamping(
            offset,
            context.read<SettingsProvider>(),
          );
          _sheetAnimation.animateTo(
            offset / maxOffset,
            duration: Duration.zero,
          );
          notifyListeners();
        }
      }
    });

    playPauseAnim = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 500),
    );

    lyricsAnim = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );

    // Register back-button handler once mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WillPopProvider>().registerPopper(() {
        debugPrint(
          "NowPlaying Popper: Invoked. offset: $offset, maxOffset: $maxOffset",
        );
        if (offset > maxOffset) {
          snapToExpanded(context, haptic: false);
          return false;
        }
        if (offset > maxOffset / 2) {
          snapToMini(context, haptic: true);
          return false;
        }
        return true;
      });
    });

    // Listen to player state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentMusic = context.read<CurrentMusicProvider>();
      _playingStreamSub = currentMusic.isPlayingStream.listen((playing) {
        if (playing) {
          playPauseAnim.forward();
        } else {
          playPauseAnim.reverse();
        }
      });
    });
  }

  /// Updates viewport dimensions based on active layout context.
  void updateDimensions({
    required Size screenSize,
    required double topInset,
    required double bottomInset,
  }) {
    final bool firstLoad = offset == 0.0 && prevOffset == 0.0;

    this.screenSize = screenSize;
    maxOffset = screenSize.height;
    sMaxOffset = screenSize.width;
    this.topInset = topInset;
    this.bottomInset = bottomInset;

    if (firstLoad) {
      if (_sheetAnimation.value < 0.0) {
        _sheetAnimation.value = 0.0;
      }
      offset = _sheetAnimation.value * maxOffset;
      prevOffset = offset;
    }
  }

  double applyStagedClamping(double currentOffset, SettingsProvider settings) {
    return NowPlayingPhysics.applyStagedClamping(
      currentOffset: currentOffset,
      prevOffset: prevOffset,
      maxOffset: maxOffset,
      settings: settings,
    );
  }

  PlayerAnimationData calculateAnimationData(double progressValue) {
    return NowPlayingPhysics.calculateAnimationData(
      progressValue: progressValue,
      maxOffset: maxOffset,
      topInset: topInset,
      bottomInset: bottomInset,
      bounceUp: bounceUp,
      bounceDown: bounceDown,
    );
  }

  void togglePlay(BuildContext context) {
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
      lyricsAnim.animateBack(0.0, curve: NowPlayingPhysics.bouncingCurve);
    } else {
      lyricsAnim.animateTo(1.0, curve: NowPlayingPhysics.bouncingCurve);
    }
  }

  // --- Vertical Snapping ---
  void verticalSnapping(BuildContext context) {
    final distance = prevOffset - offset;
    final speed = velocity.getVelocity().pixelsPerSecond.dy;
    const threshold = 500.0;

    if (prevOffset > maxOffset + 100.0) {
      if ((speed > threshold && distance > 10) ||
          distance > NowPlayingPhysics.actuationOffset) {
        snapToExpanded(context);
      } else {
        snapToQueue(context);
      }
    } else if (prevOffset < maxOffset - 100.0) {
      if (-speed > threshold || -distance > NowPlayingPhysics.actuationOffset) {
        snapToExpanded(context);
      } else if (context.read<SettingsProvider>().swipeToDismiss &&
          offset < -NowPlayingPhysics.actuationOffset / 2) {
        snapToDismissed(context);
      } else {
        snapToMini(context);
      }
    } else {
      if (speed > threshold || distance > NowPlayingPhysics.actuationOffset) {
        snapToMini(context);
      } else if (-speed > threshold ||
          -distance > NowPlayingPhysics.actuationOffset) {
        snapToQueue(context);
      } else {
        snapToExpanded(context);
      }
    }
  }

  void snapToExpanded(BuildContext context, {bool haptic = true}) {
    offset = maxOffset;
    if (prevOffset < maxOffset) bounceUp = true;
    if (prevOffset > maxOffset) bounceDown = true;
    snap(context, haptic: haptic);
  }

  void snapToMini(BuildContext context, {bool haptic = true}) {
    offset = 0;
    bounceDown = false;
    snap(context, haptic: haptic);
  }

  void snapToQueue(BuildContext context, {bool haptic = true}) {
    offset = maxOffset * 2;
    bounceUp = false;
    snap(context, haptic: haptic);
  }

  void snapToDismissed(BuildContext context, {bool haptic = true}) {
    offset = -0.1 * maxOffset;
    final settings = context.read<SettingsProvider>();
    _sheetAnimation
        .animateTo(
          -0.1,
          curve: NowPlayingPhysics.bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          if (haptic) {
            HapticUtils.trigger(settings, force: HapticForce.heavy);
          }
          context.read<CurrentMusicProvider>().stop();
        });
  }

  void snap(BuildContext context, {bool haptic = true}) {
    final settings = context.read<SettingsProvider>();
    _sheetAnimation
        .animateTo(
          offset / maxOffset,
          curve: NowPlayingPhysics.bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          if (haptic) {
            HapticUtils.trigger(settings);
          }
          bounceUp = false;
        });
  }

  // --- Horizontal Snapping ---
  void snapToPrev(BuildContext context) {
    sOffset = -sMaxOffset;
    final settings = context.read<SettingsProvider>();
    sAnim
        .animateTo(
          -1.0,
          curve: NowPlayingPhysics.bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          final currentMusic = context.read<CurrentMusicProvider>();
          final oldTrackId = currentMusic.currentTrack?.id;

          sOffset = 0;
          sAnim.animateTo(0.0, duration: Duration.zero);
          currentMusic.playPrevious();

          if (currentMusic.currentTrack?.id != oldTrackId) {
            HapticUtils.trigger(settings);
          }
        });
  }

  void snapToCurrent() {
    sOffset = 0;
    sAnim.animateTo(
      0.0,
      curve: NowPlayingPhysics.bouncingCurve,
      duration: const Duration(milliseconds: 300),
    );
  }

  void snapToNext(BuildContext context) {
    sOffset = sMaxOffset;
    final settings = context.read<SettingsProvider>();
    sAnim
        .animateTo(
          1.0,
          curve: NowPlayingPhysics.bouncingCurve,
          duration: const Duration(milliseconds: 300),
        )
        .then((_) {
          final currentMusic = context.read<CurrentMusicProvider>();
          final oldTrackId = currentMusic.currentTrack?.id;

          sOffset = 0;
          sAnim.animateTo(0.0, duration: Duration.zero);
          currentMusic.playNext();

          if (currentMusic.currentTrack?.id != oldTrackId) {
            HapticUtils.trigger(settings);
          }
        });
  }

  // Pointer & Drag Handlers
  void onPointerDown(PointerDownEvent event) {
    isFingerDown = true;
    if (isReordering) return;
    if (event.position.dy > screenSize.height - NowPlayingPhysics.deadSpace)
      return;
    startY = event.position.dy;
    activeGesture = ActiveGesture.none;
    velocity.addPosition(event.timeStamp, event.position);
    prevOffset = offset;
    bounceUp = false;
    bounceDown = false;
  }

  void onPointerMove(PointerMoveEvent event, BuildContext context) {
    if (event.position.dy > screenSize.height - NowPlayingPhysics.deadSpace)
      return;
    if (activeGesture == ActiveGesture.horizontal || isReordering) return;

    velocity.addPosition(event.timeStamp, event.position);

    final settings = context.read<SettingsProvider>();
    final dy = event.delta.dy.abs();
    final dx = event.delta.dx.abs();

    if (activeGesture == ActiveGesture.none) {
      if (dy > dx && dy > 2) {
        if (offset >= maxOffset - 10.0) {
          final bool isHandle = event.position.dy < topInset + 160.0;
          if (!isHandle) return;
        }
        activeGesture = ActiveGesture.vertical;
      } else if (dx > dy && dx > 2) {
        activeGesture = ActiveGesture.horizontal;
        return;
      } else {
        return;
      }
    }

    final deltaY = event.delta.dy;
    final isUp = deltaY < 0;
    final isDown = deltaY > 0;

    if (offset >= maxOffset - 10.0) {
      final bool isAtTop =
          offset < (maxOffset * 2 - 10.0) ||
          !queueScrollController.hasClients ||
          queueScrollController.offset <= 0;
      final bool isHandle = event.position.dy < topInset + 160.0;

      if (!isHandle) {
        if (isUp && offset >= maxOffset * 2 - 1) return;
        if (isDown) {
          if (!isAtTop) return;
          final totalDy = event.position.dy - startY;
          if (totalDy < 20.0) return;
        }
      }
    }

    offset -= deltaY;
    offset = applyStagedClamping(offset, settings);
    _sheetAnimation.animateTo(offset / maxOffset, duration: Duration.zero);
  }

  void onPointerUp(PointerUpEvent event, BuildContext context) {
    isFingerDown = false;
    if (isReordering) return;
    if (activeGesture == ActiveGesture.vertical) {
      verticalSnapping(context);
    }
    activeGesture = ActiveGesture.none;
  }

  void onPointerCancel(PointerCancelEvent event, BuildContext context) {
    isFingerDown = false;
    if (isReordering) return;
    if (activeGesture == ActiveGesture.vertical) {
      verticalSnapping(context);
    }
    activeGesture = ActiveGesture.none;
  }

  void onTap(BuildContext context) {
    if (_sheetAnimation.value <
        (NowPlayingPhysics.actuationOffset / maxOffset)) {
      snapToExpanded(context);
    }
  }

  void onVerticalDragUpdate(DragUpdateDetails details, BuildContext context) {
    if (activeGesture == ActiveGesture.horizontal || isReordering) return;
    if (details.globalPosition.dy >
        screenSize.height - NowPlayingPhysics.deadSpace)
      return;
    if (activeGesture == ActiveGesture.none) {
      activeGesture = ActiveGesture.vertical;
    }
    final settings = context.read<SettingsProvider>();
    final deltaY = details.primaryDelta ?? 0;
    final isUp = deltaY < 0;
    final isDown = deltaY > 0;

    if (offset >= maxOffset - 10.0) {
      final bool isAtTop =
          offset < (maxOffset * 2 - 10.0) ||
          !queueScrollController.hasClients ||
          queueScrollController.offset <= 0;
      final bool isHandle = details.globalPosition.dy < topInset + 160.0;

      if (!isHandle) {
        if (isUp && offset >= maxOffset * 2 - 1) return;
        if (isDown && !isAtTop) return;
      }
    }

    offset -= deltaY;
    offset = applyStagedClamping(offset, settings);
    _sheetAnimation.animateTo(offset / maxOffset, duration: Duration.zero);
  }

  void onVerticalDragEnd(DragEndDetails details, BuildContext context) {
    activeGesture = ActiveGesture.none;
    verticalSnapping(context);
  }

  void onHorizontalDragStart(DragStartDetails details, BuildContext context) {
    if (offset > maxOffset) return;
    if (activeGesture == ActiveGesture.vertical) return;
    if (!context.read<SettingsProvider>().swipeToChangeTrack) return;
    activeGesture = ActiveGesture.horizontal;
    sPrevOffset = sOffset;
  }

  void onHorizontalDragUpdate(DragUpdateDetails details, BuildContext context) {
    if (offset > maxOffset) return;
    final settings = context.read<SettingsProvider>();
    if (!settings.swipeToChangeTrack) return;
    if (activeGesture == ActiveGesture.vertical) return;
    if (details.globalPosition.dy >
        screenSize.height - NowPlayingPhysics.deadSpace)
      return;

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

    double minClamp = canPrev ? -sMaxOffset : 0.0;
    double maxClamp = canNext ? sMaxOffset : 0.0;

    sOffset = sOffset.clamp(minClamp, maxClamp);
    sAnim.animateTo(sOffset / sMaxOffset, duration: Duration.zero);
  }

  void onHorizontalDragEnd(DragEndDetails details, BuildContext context) {
    if (offset > maxOffset) return;
    activeGesture = ActiveGesture.none;
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
            distance >
                NowPlayingPhysics.actuationOffset *
                    NowPlayingPhysics.sActuationMulti)) {
      snapToPrev(context);
    } else if (canNext &&
        (-speed > threshold ||
            -distance >
                NowPlayingPhysics.actuationOffset *
                    NowPlayingPhysics.sActuationMulti)) {
      snapToNext(context);
    } else {
      snapToCurrent();
    }
  }

  @override
  void dispose() {
    _playingStreamSub?.cancel();
    sAnim.dispose();
    queueScrollController.dispose();
    playPauseAnim.dispose();
    lyricsAnim.dispose();
    super.dispose();
  }
}
