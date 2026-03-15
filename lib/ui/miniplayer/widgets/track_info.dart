import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import '../../../core/math_utils.dart';

class TrackInfo extends StatelessWidget {
  final Animation<double> sAnim;
  final double sMaxOffset;
  final double stParallax;
  final double queueProgressValue;
  final double maxOffset;
  final double topInset;
  final bool bounceUp;
  final bool bounceDown;
  final double bounceProgressValue;
  final double bottomOffset;
  final double bounceClampedProgressValue;
  final Size screenSize;

  const TrackInfo({
    super.key,
    required this.sAnim,
    required this.sMaxOffset,
    required this.stParallax,
    required this.queueProgressValue,
    required this.maxOffset,
    required this.topInset,
    required this.bounceUp,
    required this.bounceDown,
    required this.bounceProgressValue,
    required this.bottomOffset,
    required this.bounceClampedProgressValue,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final currentMusic = context.watch<CurrentMusicProvider>();
    final music = context.watch<MusicProvider>();
    final song = currentMusic.currentSong;
    final title = song?.title ?? 'No track';
    final artist = song?.artist ?? '';
    final isFav = song != null ? music.isFavorite(song) : false;

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
                    (12.0 * queueProgressValue),
                (-maxOffset + topInset + 102.0) *
                    (!bounceUp
                        ? !bounceDown
                              ? queueProgressValue
                              : (1 - bounceProgressValue)
                        : 0.0),
              ),
              child: Transform.translate(
                offset: Offset(
                  0,
                  bottomOffset +
                      (-maxOffset / 3.6 * bounceProgressValue.clamp(0, 2)),
                ),
                child: Padding(
                  padding:
                      EdgeInsets.all(
                        12.0 * (1 - bounceClampedProgressValue),
                      ).add(
                        EdgeInsets.symmetric(
                          horizontal: 16.0 * bounceClampedProgressValue,
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
                            c: bounceClampedProgressValue,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        height: rangeProgress(
                          a: 58.0,
                          b: 82.0,
                          c: bounceClampedProgressValue,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: rangeProgress(
                                a: 82.0,
                                b: 8.0,
                                c: bounceClampedProgressValue,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 42.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: rangeProgress(
                                          a: 18.0,
                                          b: 24.0,
                                          c: bounceProgressValue,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        height: 1,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: rangeProgress(
                                          a: 15.0,
                                          b: 17.0,
                                          c: bounceProgressValue,
                                        ),
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Favorite Icon
                            Opacity(
                              opacity:
                                  (inverseAboveOne(bounceProgressValue) * 10 - 9).clamp(0, 1),
                              child: Transform.translate(
                                offset: Offset(
                                  -100 * (1.0 - bounceClampedProgressValue),
                                  0.0,
                                ),
                                child: GestureDetector(
                                  onTap: song != null
                                      ? () => music.toggleFavorite(song)
                                      : null,
                                  child: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    size: 32.0,
                                    color: isFav
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSecondaryContainer,
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
