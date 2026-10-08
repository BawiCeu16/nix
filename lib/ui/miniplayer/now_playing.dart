import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:provider/provider.dart';

import 'package:nix/core/math_utils.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/ui/miniplayer/widgets/top_bar.dart';
import 'package:nix/ui/miniplayer/widgets/track_image.dart';
import 'package:nix/ui/miniplayer/widgets/track_info.dart';
import 'package:nix/ui/miniplayer/widgets/player_controls.dart';
import 'package:nix/ui/miniplayer/widgets/queue_view.dart';
import 'package:nix/ui/miniplayer/controllers/now_playing_controller.dart';
import 'package:nix/ui/miniplayer/models/animation_data.dart';

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
  late final NowPlayingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NowPlayingController()
      ..init(vsync: this, sheetAnimation: widget.animation, context: context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.updateDimensions(
      screenSize: MediaQuery.of(context).size,
      topInset: MediaQuery.of(context).padding.top,
      bottomInset: widget.bottomInset,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final track = context.select<CurrentMusicProvider, Track?>(
    //   (p) => p.currentTrack,
    // );
    final settings = context.watch<SettingsProvider>();
    final showMiniplayerShadow = settings.showMiniplayerShadow;
    final miniplayerShadowStyle = settings.miniplayerShadowStyle;
    final miniplayerShadowOpacity = settings.miniplayerShadowOpacity;
    final Color onSecondary = Theme.of(
      context,
    ).colorScheme.onSecondaryContainer;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Listener(
          onPointerDown: (event) => _controller.onPointerDown(event),
          onPointerMove: (event) => _controller.onPointerMove(event, context),
          onPointerUp: (event) => _controller.onPointerUp(event, context),
          onPointerCancel: (event) =>
              _controller.onPointerCancel(event, context),
          child: GestureDetector(
            onTap: () => _controller.onTap(context),
            onVerticalDragUpdate: (details) =>
                _controller.onVerticalDragUpdate(details, context),
            onVerticalDragEnd: (details) =>
                _controller.onVerticalDragEnd(details, context),
            onHorizontalDragStart: (details) =>
                _controller.onHorizontalDragStart(details, context),
            onHorizontalDragUpdate: (details) =>
                _controller.onHorizontalDragUpdate(details, context),
            onHorizontalDragEnd: (details) =>
                _controller.onHorizontalDragEnd(details, context),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                widget.animation,
                _controller.swipeFadeAnim,
              ]),
              builder: (context, child) {
                final data = _controller.calculateAnimationData(
                  widget.animation.value,
                );

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
                                      if (miniplayerShadowStyle !=
                                          MiniplayerShadowStyle.expressive)
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
                                                        data.inverseClampedProgress *
                                                        miniplayerShadowOpacity,
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
                        onSnapToMini: () => _controller.snapToMini(context),
                      ),
                    // Queue access button
                    AnimatedBuilder(
                      animation: _controller.lyricsAnim,
                      builder: (context, child) {
                        return Offstage(
                          offstage: data.opacity == 0.0,
                          child: Material(
                            type: MaterialType.transparency,
                            child: Opacity(
                              opacity:
                                  (data.opacity *
                                          (1 - _controller.lyricsAnim.value))
                                      .clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  -100 * data.inverseProgress +
                                      (100 * _controller.lyricsAnim.value),
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
                                        onPressed: () =>
                                            _controller.snapToQueue(context),
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
                    // Action controls (Shuffle, Favorite, Repeat)
                    AnimatedBuilder(
                      animation: _controller.lyricsAnim,
                      builder: (context, child) {
                        return Offstage(
                          offstage: data.opacity == 0.0,
                          child: Material(
                            type: MaterialType.transparency,
                            child: Opacity(
                              opacity:
                                  (data.opacity *
                                          (1 - _controller.lyricsAnim.value))
                                      .clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  -100 * data.inverseProgress +
                                      (100 * _controller.lyricsAnim.value),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14.0,
                                      ),
                                      child: Consumer<CurrentMusicProvider>(
                                        builder: (context, music, _) {
                                          return ValueListenableBuilder<
                                            Box<int>
                                          >(
                                            valueListenable: Hive.box<int>(
                                              HiveKeys.favoritesBox,
                                            ).listenable(),
                                            builder: (context, box, _) {
                                              final track = music.currentTrack;
                                              final isFavorite =
                                                  track != null &&
                                                  box.containsKey(track.id);
                                              final selectedIndices = <int>{
                                                if (music.isShuffleEnabled) 0,
                                                if (isFavorite) 1,
                                                if (music.isRepeatEnabled) 2,
                                              };

                                              return M3EToggleButtonGroup(
                                                type: M3EButtonGroupType
                                                    .connected,
                                                style: M3EButtonStyle.tonal,
                                                size: M3EButtonSize.custom(
                                                  height: 45,
                                                ),
                                                decoration:
                                                    M3EToggleButtonDecoration.styleFrom(
                                                      foregroundColor:
                                                          onSecondary,
                                                      checkedForegroundColor:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .surfaceContainer
                                                              .withValues(
                                                                alpha: 1,
                                                              ),
                                                      checkedBackgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primaryContainer,
                                                    ),
                                                selectedIndices:
                                                    selectedIndices,
                                                onSelectedIndicesChanged:
                                                    (newIndices) {
                                                      if (newIndices.contains(
                                                            0,
                                                          ) !=
                                                          music
                                                              .isShuffleEnabled) {
                                                        music.toggleShuffle();
                                                      }
                                                      if (newIndices.contains(
                                                            1,
                                                          ) !=
                                                          isFavorite) {
                                                        if (track != null) {
                                                          music.customAction(
                                                            'favorite',
                                                          );
                                                        }
                                                      }
                                                      if (newIndices.contains(
                                                            2,
                                                          ) !=
                                                          music
                                                              .isRepeatEnabled) {
                                                        music.toggleRepeat();
                                                      }
                                                    },
                                                actions: [
                                                  M3EToggleButtonGroupAction(
                                                    icon: const Icon(
                                                      FlutterRemix.shuffle_line,
                                                      size: 20.0,
                                                    ),
                                                    checkedIcon: Icon(
                                                      FlutterRemix.shuffle_line,
                                                      size: 20.0,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                                    tooltip: 'Shuffle',
                                                  ),
                                                  M3EToggleButtonGroupAction(
                                                    icon: const Icon(
                                                      FlutterRemix.heart_3_line,
                                                      size: 20.0,
                                                    ),
                                                    checkedIcon: Icon(
                                                      FlutterRemix.heart_3_fill,
                                                      size: 20.0,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                                    tooltip: 'Favorite',
                                                    width: 62,
                                                  ),
                                                  M3EToggleButtonGroupAction(
                                                    icon: const Icon(
                                                      FlutterRemix
                                                          .repeat_2_line,
                                                      size: 20.0,
                                                    ),
                                                    checkedIcon: Icon(
                                                      music.isRepeatOne
                                                          ? FlutterRemix
                                                                .repeat_one_line
                                                          : FlutterRemix
                                                                .repeat_2_line,
                                                      size: 20.0,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                                    tooltip: 'Repeat',
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
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
                    // Audio output button (BottomLeft)
                    // AnimatedBuilder(
                    //   animation: _controller.lyricsAnim,
                    //   builder: (context, child) {
                    //     return Offstage(
                    //       offstage: data.opacity == 0.0,
                    //       child: Material(
                    //         type: MaterialType.transparency,
                    //         child: Opacity(
                    //           opacity:
                    //               (data.opacity *
                    //                       (1 - _controller.lyricsAnim.value))
                    //                   .clamp(0.0, 1.0),
                    //           child: Transform.translate(
                    //             offset: Offset(
                    //               0,
                    //               -100 * data.inverseProgress +
                    //                   (100 * _controller.lyricsAnim.value),
                    //             ),
                    //             child: Align(
                    //               alignment: Alignment.bottomLeft,
                    //               child: SafeArea(
                    //                 child: Padding(
                    //                   padding: const EdgeInsets.symmetric(
                    //                     horizontal: 16.0,
                    //                     vertical: 14.0,
                    //                   ),
                    //                   child: AudioOutputButton(
                    //                     onSecondary: onSecondary,
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),
                    //Lyrics section
                    // AnimatedBuilder(
                    //   animation: _controller.lyricsAnim,
                    //   builder: (context, _) {
                    //     return LyricsSection(
                    //       lyricsAnim: _controller.lyricsAnim,
                    //       data: data,
                    //       maxOffset: _controller.maxOffset,
                    //       topInset: _controller.topInset,
                    //       track: track,
                    //     );
                    //   },
                    // ),
                    //Track info and image:
                    //Cutoff and dynamic linear edge fading (with fade in/out animation) are active when swipe to skip next and previous is triggered in the Miniplayer section only
                    ClipRRect(
                      clipBehavior:
                          (data.clampedProgress <= 0.4 &&
                                  _controller.isSwipingTrack)
                              ? Clip.antiAlias
                              : Clip.none,
                      clipper: MiniplayerContainerClipper(
                        data: data,
                        screenSize: _controller.screenSize,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 4.0,
                        ),
                      ),
                      child: SwipeFadeMask(
                        enabled: data.clampedProgress <= 0.4 &&
                            _controller.isSwipingTrack,
                        fadeProgress: math.max(
                          _controller.swipeFadeAnim.value,
                          (_controller.sAnim.value.abs() * 3.0).clamp(0.0, 1.0),
                        ),
                        hPadding: 12.0 *
                            (1 - data.clampedProgress * 10 + 9).clamp(
                              0.0,
                              1.0,
                            ),
                        child: Stack(
                          children: [
                            TrackInfo(
                              sAnim: _controller.sAnim,
                              sMaxOffset: _controller.sMaxOffset,
                              stParallax: _controller.stParallax,
                              maxOffset: _controller.maxOffset,
                              topInset: _controller.topInset,
                              bounceUp: _controller.bounceUp,
                              bounceDown: _controller.bounceDown,
                              screenSize: _controller.screenSize,
                              data: data,
                              lyricsAnim: _controller.lyricsAnim,
                              onToggleLyrics: _controller.toggleLyrics,
                            ),
                            TrackImage(
                              sAnim: _controller.sAnim,
                              sMaxOffset: _controller.sMaxOffset,
                              siParallax: _controller.siParallax,
                              bounceUp: _controller.bounceUp,
                              maxOffset: _controller.maxOffset,
                              topInset: _controller.topInset,
                              bounceDown: _controller.bounceDown,
                              screenSize: _controller.screenSize,
                              data: data,
                              lyricsAnim: _controller.lyricsAnim,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Player controls
                    PlayerControls(
                      maxOffset: _controller.maxOffset,
                      topInset: _controller.topInset,
                      bounceUp: _controller.bounceUp,
                      bounceDown: _controller.bounceDown,
                      onSecondary: onSecondary,
                      screenSize: _controller.screenSize,
                      onTogglePlay: () => _controller.togglePlay(context),
                      playPauseAnim: _controller.playPauseAnim,
                      data: data,
                      lyricsAnim: _controller.lyricsAnim,
                      onNext: () => _controller.snapToNext(context),
                      onPrevious: () => _controller.snapToPrev(context),
                    ),
                    //Queue view
                    QueueView(
                      queueProgressValue: data.queueProgress,
                      maxOffset: _controller.maxOffset,
                      topInset: _controller.topInset,
                      controller: _controller.queueScrollController,
                      onReorderBegin: () {
                        if (!_controller.isReordering) {
                          _controller.isReordering = true;
                        }
                      },
                      onReorderEnd: () {
                        if (_controller.isReordering) {
                          _controller.isReordering = false;
                        }
                      },
                      onClose: () => _controller.snapToExpanded(context),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Clips track information and artwork to the bounds and border radius
/// of the Miniplayer container with a margin so horizontal swipe animations do not bleed outside.
class MiniplayerContainerClipper extends CustomClipper<RRect> {
  final PlayerAnimationData data;
  final Size screenSize;
  final EdgeInsets margin;

  MiniplayerContainerClipper({
    required this.data,
    required this.screenSize,
    this.margin = const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
  });

  @override
  RRect getClip(Size size) {
    final double hPadding =
        12.0 * (1 - data.clampedProgress * 10 + 9).clamp(0.0, 1.0);
    final double vPadding = 12.0 * data.inverseClampedProgress;
    final double height = rangeProgress(
      a: 82.0,
      b: data.panelHeight,
      c: data.progress.clamp(0.0, 3.0),
    );
    final double bottom =
        size.height + data.bottomOffset - vPadding - margin.bottom;
    final double top = bottom - (height - margin.top - margin.bottom);
    final double left = hPadding + margin.left;
    final double right = size.width - hPadding - margin.right;

    final double radius =
        (20.0 - (margin.left + margin.top) / 2).clamp(8.0, 20.0);

    return RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      Radius.circular(radius),
    );
  }

  @override
  bool shouldReclip(covariant MiniplayerContainerClipper oldClipper) {
    return oldClipper.data.progress != data.progress ||
        oldClipper.data.bottomOffset != data.bottomOffset ||
        oldClipper.screenSize != screenSize ||
        oldClipper.margin != margin;
  }
}

/// An ultra-optimized shader mask that applies a dynamic linear fade to the
/// left and right edges of the Miniplayer container with smooth fade in/out animation.
///
/// When disabled (resting or expanded), zero compositing layers or shaders are created.
class SwipeFadeMask extends SingleChildRenderObjectWidget {
  final bool enabled;
  final double fadeProgress;
  final double hPadding;
  final double marginH;
  final double fadeWidth;

  const SwipeFadeMask({
    super.key,
    required this.enabled,
    required this.fadeProgress,
    required this.hPadding,
    this.marginH = 6.0,
    this.fadeWidth = 28.0,
    required Widget super.child,
  });

  @override
  RenderSwipeFadeMask createRenderObject(BuildContext context) {
    return RenderSwipeFadeMask(
      enabled: enabled,
      fadeProgress: fadeProgress,
      hPadding: hPadding,
      marginH: marginH,
      fadeWidth: fadeWidth,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSwipeFadeMask renderObject,
  ) {
    renderObject
      ..enabled = enabled
      ..fadeProgress = fadeProgress
      ..hPadding = hPadding
      ..marginH = marginH
      ..fadeWidth = fadeWidth;
  }
}

class RenderSwipeFadeMask extends RenderProxyBox {
  RenderSwipeFadeMask({
    required bool enabled,
    required double fadeProgress,
    required double hPadding,
    required double marginH,
    required double fadeWidth,
    RenderBox? child,
  })  : _enabled = enabled,
        _fadeProgress = fadeProgress,
        _hPadding = hPadding,
        _marginH = marginH,
        _fadeWidth = fadeWidth,
        super(child);

  bool _enabled;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    markNeedsPaint();
  }

  double _fadeProgress;
  double get fadeProgress => _fadeProgress;
  set fadeProgress(double value) {
    if (_fadeProgress == value) return;
    _fadeProgress = value;
    if (_enabled) markNeedsPaint();
  }

  double _hPadding;
  double get hPadding => _hPadding;
  set hPadding(double value) {
    if (_hPadding == value) return;
    _hPadding = value;
    if (_enabled) markNeedsPaint();
  }

  double _marginH;
  double get marginH => _marginH;
  set marginH(double value) {
    if (_marginH == value) return;
    _marginH = value;
    if (_enabled) markNeedsPaint();
  }

  double _fadeWidth;
  double get fadeWidth => _fadeWidth;
  set fadeWidth(double value) {
    if (_fadeWidth == value) return;
    _fadeWidth = value;
    if (_enabled) markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => _enabled;

  Shader _createShader(Rect bounds) {
    final double w = bounds.width;
    if (w <= 0) {
      return const LinearGradient(
        colors: [Colors.white, Colors.white],
      ).createShader(bounds);
    }

    final double left = _hPadding + _marginH;
    final double right = w - _hPadding - _marginH;
    final double rightFadeWidth = _fadeWidth * _fadeProgress;
    final double leftFadeWidth = _fadeWidth * _fadeProgress;

    const double stop0 = 0.0;
    final double stop1 = (left / w).clamp(0.0, 1.0);
    final double stop2 = ((left + leftFadeWidth) / w).clamp(stop1, 1.0);
    final double stop4 = (right / w).clamp(stop2, 1.0);
    final double stop3 = ((right - rightFadeWidth) / w).clamp(stop2, stop4);
    const double stop5 = 1.0;

    final Color edgeColor = Color.lerp(
      Colors.black,
      Colors.transparent,
      _fadeProgress,
    )!;

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        edgeColor,
        edgeColor,
        Colors.black,
        Colors.black,
        edgeColor,
        edgeColor,
      ],
      stops: [stop0, stop1, stop2, stop3, stop4, stop5],
    ).createShader(bounds);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    if (!_enabled) {
      super.paint(context, offset);
      return;
    }

    final Rect rect = offset & size;
    context.pushLayer(
      ShaderMaskLayer(
        shader: _createShader(rect),
        maskRect: rect,
        blendMode: BlendMode.dstIn,
      ),
      super.paint,
      offset,
    );
  }
}
