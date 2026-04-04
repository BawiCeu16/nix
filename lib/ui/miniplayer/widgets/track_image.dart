import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import '../../../core/math_utils.dart';
import '../models/animation_data.dart';

class TrackImage extends StatelessWidget {
  final Animation<double> sAnim;
  final double sMaxOffset;
  final double siParallax;
  final bool bounceUp;
  final double maxOffset;
  final double topInset;
  final bool bounceDown;
  final Size screenSize;
  final PlayerAnimationData data;

  const TrackImage({
    super.key,
    required this.sAnim,
    required this.sMaxOffset,
    required this.siParallax,
    required this.bounceUp,
    required this.maxOffset,
    required this.topInset,
    required this.bounceDown,
    required this.screenSize,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final currentSong = context.watch<CurrentMusicProvider>().currentSong;

    return AnimatedBuilder(
      animation: sAnim,
      builder: (context, child) {
        return Opacity(
          opacity: 1 - sAnim.value.abs(),
          child: Transform.translate(
            offset: Offset(
              -sAnim.value * sMaxOffset / siParallax,
              !bounceUp
                  ? (-maxOffset + topInset + 108.0) *
                        (!bounceDown
                            ? data.queueProgress
                            : (1 - data.bounceProgress))
                  : 0.0,
            ),
            child: Transform.translate(
              offset: Offset(
                0,
                data.bottomOffset +
                    (-maxOffset / 2.30 * data.bounceProgress.clamp(0, 2)),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  12.0 * (1 - data.bounceClampedProgress),
                ).add(EdgeInsets.only(left: 22.0 * data.bounceClampedProgress)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                    height: rangeProgress(
                      a: 82.0,
                      b: screenSize.width - 46.0,
                      c: data.bounceClampedProgress,
                    ),
                    width: rangeProgress(
                      a: 82.0,
                      b: screenSize.width - 46.0,
                      c: data.bounceClampedProgress,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        12.0 * (1 - data.bounceClampedProgress),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          rangeProgress(
                            a: 100.0,
                            b: 15.0,
                            c: data.bounceClampedProgress,
                          ),
                        ),
                        child: currentSong != null
                            ? QueryArtworkWidget(
                                id: currentSong.id,
                                type: ArtworkType.AUDIO,
                                keepOldArtwork: true,
                                artworkFit: BoxFit.cover,
                                artworkBorder: BorderRadius.circular(15),
                                artworkQuality: FilterQuality.high,
                                artworkWidth: 800,
                                artworkHeight: 800,
                                nullArtworkWidget: Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: Center(
                                    child: Icon(
                                      FlutterRemix.music_2_fill,
                                      size: 40,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: .5),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Center(
                                  child: Icon(
                                    FlutterRemix.music_2_fill,
                                    size: 40,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: .5),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
