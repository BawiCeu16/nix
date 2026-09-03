import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/services/snackbar_service.dart';
import 'package:nix/core/haptic_utils.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/core/math_utils.dart';
import 'package:nix/ui/miniplayer/models/animation_data.dart';

class TrackInfo extends StatelessWidget {
  final Animation<double> sAnim;
  final double sMaxOffset;
  final double stParallax;
  final double maxOffset;
  final double topInset;
  final bool bounceUp;
  final bool bounceDown;
  final Size screenSize;
  final PlayerAnimationData data;
  final Animation<double> lyricsAnim;
  final VoidCallback onToggleLyrics;

  const TrackInfo({
    super.key,
    required this.sAnim,
    required this.sMaxOffset,
    required this.stParallax,
    required this.maxOffset,
    required this.topInset,
    required this.bounceUp,
    required this.bounceDown,
    required this.screenSize,
    required this.data,
    required this.lyricsAnim,
    required this.onToggleLyrics,
  });

  Widget _buildSingleTrackInfo(BuildContext context, Track? track) {
    final title = track?.title ?? 'No track';
    final artist = track?.artist ?? '';
    final bool isNowPlaying =
        data.clampedProgress > 0.8 && data.queueProgress < 0.2;
    final bool isMiniplayer = data.clampedProgress < 0.5;
    final animDuration =
        isMiniplayer ? const Duration(milliseconds: 300) : Duration.zero;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: animDuration,
          transitionBuilder: (child, animation) {
            if (!isMiniplayer) {
              return Align(alignment: Alignment.centerLeft, child: child);
            }
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuad,
                      ),
                    ),
                child: Align(alignment: Alignment.centerLeft, child: child),
              ),
            );
          },
          child: GestureDetector(
            key: ValueKey(title),
            onLongPress:
                (isNowPlaying && track != null && track.title.isNotEmpty)
                ? () {
                    Clipboard.setData(ClipboardData(text: track.title));
                    HapticUtils.trigger(context.read<SettingsProvider>());
                    context.showSnackBar('Title copied to clipboard');
                  }
                : null,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: rangeProgress(
                  a: 18.0,
                  b: 24.0 - (5.0 * lyricsAnim.value),
                  c: data.bounceProgress,
                ),
                fontWeight: FontWeight.w600,
                height: 1,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: animDuration,
          transitionBuilder: (child, animation) {
            if (!isMiniplayer) {
              return Align(alignment: Alignment.centerLeft, child: child);
            }
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuad,
                      ),
                    ),
                child: Align(alignment: Alignment.centerLeft, child: child),
              ),
            );
          },
          child: Text(
            artist,
            key: ValueKey(artist),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rangeProgress(
                a: 15.0,
                b: 17.0 - (3.0 * lyricsAnim.value),
                c: data.bounceProgress,
              ),
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .7),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = context.select<CurrentMusicProvider, Track?>(
      (p) => p.currentTrack,
    );
    final nextTrack = context.select<CurrentMusicProvider, Track?>(
      (p) => p.nextTrack,
    );
    final previousTrack = context.select<CurrentMusicProvider, Track?>(
      (p) => p.previousTrack,
    );

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge([sAnim, lyricsAnim]),
        builder: (context, child) {
          final double sVal = sAnim.value;
          final double absSVal = sVal.abs().clamp(0.0, 1.0);
          final double currentOpacity = (1.0 - absSVal).clamp(0.0, 1.0);
          final double incomingOpacity = absSVal;

          return Transform.translate(
            offset: Offset(
              -sVal * sMaxOffset / stParallax + (12.0 * data.queueProgress),
              (-maxOffset + topInset + 102.0) *
                  (!bounceUp
                      ? !bounceDown
                            ? data.queueProgress
                            : (1 - data.bounceProgress)
                      : 0.0),
            ),
            child: Transform.translate(
              offset: Offset(
                0,
                data.bottomOffset +
                    (-maxOffset / 3.6 * data.bounceProgress.clamp(0, 2)) +
                    (140.0 * lyricsAnim.value * data.bounceClampedProgress),
              ),
              child: Padding(
                padding: EdgeInsets.all(12.0 * (1 - data.bounceClampedProgress))
                    .add(
                      EdgeInsets.only(
                        left:
                            20.0 * data.bounceClampedProgress +
                            (72.0 *
                                lyricsAnim.value *
                                data.bounceClampedProgress),
                        right: 20.0 * data.bounceClampedProgress,
                      ),
                    ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0).add(
                      EdgeInsets.only(
                        bottom: rangeProgress(
                          a: 0,
                          b: screenSize.width / 16,
                          c: data.bounceClampedProgress,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      height: rangeProgress(
                        a: 58.0,
                        b: 82.0,
                        c: data.bounceClampedProgress,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: rangeProgress(
                              a: 82.0,
                              b: 8.0,
                              c: data.bounceClampedProgress,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: rangeProgress(
                                  a: 88.0,
                                  b: 8.0,
                                  c: data.bounceClampedProgress,
                                ),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // 1. Next Track Info (sliding from right when swiping left, sVal > 0)
                                  if (sVal > 0.001)
                                    Positioned.fill(
                                      child: Transform.translate(
                                        offset: Offset(sMaxOffset, 0),
                                        child: Opacity(
                                          opacity: incomingOpacity,
                                          child: _buildSingleTrackInfo(
                                            context,
                                            nextTrack,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // 2. Previous Track Info (sliding from left when swiping right, sVal < 0)
                                  if (sVal < -0.001)
                                    Positioned.fill(
                                      child: Transform.translate(
                                        offset: Offset(-sMaxOffset, 0),
                                        child: Opacity(
                                          opacity: incomingOpacity,
                                          child: _buildSingleTrackInfo(
                                            context,
                                            previousTrack,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // 3. Current Track Info
                                  Positioned.fill(
                                    child: Opacity(
                                      opacity: currentOpacity,
                                      child: _buildSingleTrackInfo(
                                        context,
                                        currentTrack,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Favorite IconButton
                          // Consumer<MusicProvider>(
                          //   builder: (context, musicProvider, _) {
                          //     final isFav =
                          //         currentTrack != null &&
                          //         musicProvider.isFavorite(currentTrack);
                          //     final favOpacity =
                          //         ((inverseAboveOne(data.bounceProgress) * 10 -
                          //                         9)
                          //                     .clamp(0.0, 1.0) *
                          //                 (1.0 - lyricsAnim.value))
                          //             .clamp(0.0, 1.0);

                          //     if (favOpacity == 0.0) {
                          //       return const SizedBox();
                          //     }

                          //     return Opacity(
                          //       opacity: favOpacity,
                          //       child: Transform.translate(
                          //         offset: Offset(
                          //           -100 * (1.0 - data.bounceClampedProgress),
                          //           0.0,
                          //         ),
                          //         child: IconButton(
                          //           onPressed: currentTrack != null
                          //               ? () {
                          //                   musicProvider.toggleFavorite(
                          //                     currentTrack,
                          //                   );
                          //                   HapticUtils.trigger(
                          //                     context.read<SettingsProvider>(),
                          //                   );
                          //                 }
                          //               : null,
                          //           icon: Icon(
                          //             isFav
                          //                 ? FlutterRemix.heart_3_fill
                          //                 : FlutterRemix.heart_3_line,
                          //             size: 26.0,
                          //             color: isFav
                          //                 ? Theme.of(
                          //                     context,
                          //                   ).colorScheme.primary
                          //                 : Theme.of(context)
                          //                       .colorScheme
                          //                       .onSurface
                          //                       .withValues(alpha: .7),
                          //           ),
                          //         ),
                          //       ),
                          //     );
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
