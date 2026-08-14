import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';

import 'package:nix/core/math_utils.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/miniplayer/widgets/top_bar.dart';
import 'package:nix/ui/miniplayer/widgets/track_image.dart';
import 'package:nix/ui/miniplayer/widgets/track_info.dart';
import 'package:nix/ui/miniplayer/widgets/player_controls.dart';
import 'package:nix/ui/miniplayer/widgets/queue_view.dart';
import 'package:nix/ui/miniplayer/controllers/now_playing_controller.dart';

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
    final showMiniplayerShadow = context.select<SettingsProvider, bool>(
      (s) => s.showMiniplayerShadow,
    );
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
              animation: widget.animation,
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
                    //Track info
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
                    //Track image
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
