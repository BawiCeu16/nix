import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import '../../../core/math_utils.dart';

class TrackImage extends StatelessWidget {
  final Animation<double> sAnim;
  final double sMaxOffset;
  final double siParallax;
  final bool bounceUp;
  final double maxOffset;
  final double topInset;
  final bool bounceDown;
  final double queueProgressValue;
  final double bounceProgressValue;
  final double bottomOffset;
  final double bounceClampedProgressValue;
  final Size screenSize;

  const TrackImage({
    super.key,
    required this.sAnim,
    required this.sMaxOffset,
    required this.siParallax,
    required this.bounceUp,
    required this.maxOffset,
    required this.topInset,
    required this.bounceDown,
    required this.queueProgressValue,
    required this.bounceProgressValue,
    required this.bottomOffset,
    required this.bounceClampedProgressValue,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final currentSong = context.watch<CurrentMusicProvider>().currentSong;

    Uint8List? artworkBytes;
    if (currentSong != null) {
      try {
        if (Hive.isBoxOpen('cached_images')) {
          final box = Hive.box('cached_images');
          final data = box.get(currentSong.uri);
          if (data != null && data is Uint8List) {
            artworkBytes = data;
          }
        }
      } catch (_) {}
    }

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
                            ? queueProgressValue
                            : (1 - bounceProgressValue))
                  : 0.0,
            ),
            child: Transform.translate(
              offset: Offset(
                0,
                bottomOffset +
                    (-maxOffset / 2.30 * bounceProgressValue.clamp(0, 2)),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  12.0 * (1 - bounceClampedProgressValue),
                ).add(EdgeInsets.only(left: 22.0 * bounceClampedProgressValue)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                    height: rangeProgress(
                      a: 82.0,
                      b: screenSize.width - 46.0,
                      c: bounceClampedProgressValue,
                    ),
                    width: rangeProgress(
                      a: 82.0,
                      b: screenSize.width - 46.0,
                      c: bounceClampedProgressValue,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        12.0 * (1 - bounceClampedProgressValue),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          rangeProgress(
                            a: 100.0,
                            b: 15.0,
                            c: bounceClampedProgressValue,
                          ),
                        ),
                        child: artworkBytes != null
                            ? Image.memory(
                                artworkBytes,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              )
                            : Container(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Center(
                                  child: Icon(
                                    Icons.music_note,
                                    size: 40,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: .5),
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
