import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import '../../../core/math_utils.dart';
import '../models/animation_data.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final currentMusic = context.watch<CurrentMusicProvider>();
    final music = context.watch<MusicProvider>();
    final track = currentMusic.currentTrack;
    final title = track?.title ?? 'No track';
    final artist = track?.artist ?? '';
    final isFav = track != null ? music.isFavorite(track) : false;

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: sAnim,
        builder: (context, child) {
          return Opacity(
            opacity: 1 - sAnim.value.abs(),
            child: Transform.translate(
              offset: Offset(
                -sAnim.value * sMaxOffset / stParallax +
                    (12.0 * data.queueProgress),
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
                      (-maxOffset / 3.6 * data.bounceProgress.clamp(0, 2)),
                ),
                child: Padding(
                  padding:
                      EdgeInsets.all(
                        12.0 * (1 - data.bounceClampedProgress),
                      ).add(
                        EdgeInsets.symmetric(
                          horizontal: 20.0 * data.bounceClampedProgress,
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
                                padding: const EdgeInsets.only(right: 42.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                      transitionBuilder: (child, animation) {
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
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: child,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        title,
                                        key: ValueKey(title),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: rangeProgress(
                                            a: 18.0,
                                            b: 24.0,
                                            c: data.bounceProgress,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          height: 1,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                      transitionBuilder: (child, animation) {
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
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: child,
                                            ),
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
                                            b: 17.0,
                                            c: data.bounceProgress,
                                          ),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: .7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Favorite Icon
                            Opacity(
                              opacity:
                                  (inverseAboveOne(data.bounceProgress) * 10 -
                                          9)
                                      .clamp(0, 1),
                              child: Transform.translate(
                                offset: Offset(
                                  -100 * (1.0 - data.bounceClampedProgress),
                                  0.0,
                                ),
                                child: GestureDetector(
                                  onTap: track != null
                                      ? () => music.toggleFavorite(track)
                                      : null,
                                  child: Icon(
                                    isFav
                                        ? FlutterRemix.heart_fill
                                        : FlutterRemix.heart_line,
                                    size: 32.0,
                                    color: isFav
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
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
              ),
            ),
          );
        },
      ),
    );
  }
}
