import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/%20utils/translator.dart';
import 'package:nix/providers/theme_provider.dart';
import 'package:nix/ui/pages/lyrics_page.dart';
// import 'package:nix/pages/favorite_songs_screen.dart';
import 'package:nix/ui/widgets/song_details_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:flutter_miniplayer/flutter_miniplayer.dart';
import '../../providers/music_provider.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key, required this.heightNotifier});

  final ValueNotifier<double> heightNotifier;

  static const double minHeight = 75.0;
  static const double maxHeightFraction = 1.0;

  // ✅ Helper to fetch artwork as ImageProvider
  Future<ImageProvider?> getArtworkImage(int songId) async {
    final audioQuery = OnAudioQuery();
    final bytes = await audioQuery.queryArtwork(songId, ArtworkType.AUDIO);
    if (bytes == null) return null;
    return MemoryImage(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final Musprovider = Provider.of<MusicProvider>(context);

    if (Musprovider.currentSong == null) return const SizedBox();
    final song = Musprovider.currentSong!;
    final imageSize = MediaQuery.of(context).size.width * 0.89;
    final upcomingSize = MediaQuery.of(context).size.width * 0.89;

    // ✅ Apply dynamic theme color if enabled
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (themeProvider.dynamicColorEnabled) {
      getArtworkImage(song.id).then((image) {
        if (image != null) {
          themeProvider.updateColorFromAlbum(image);
        }
      });
    }

    return Consumer<MusicProvider>(
      //Miniplayer Widget
      builder: (context, provider, _) => Miniplayer(
        tapToCollapse: false,
        onDismissed: () {
          heightNotifier.value = minHeight; // Collapse animation
          Future.delayed(const Duration(milliseconds: 200), () {
            provider.pause(); // pause music
            provider
                .clearCurrentSong(); // Hide MiniPlayer + reset song data// ✅ This now clears artwork too
          });
        },
        curve: Curves.easeOutCubic,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        minHeight: minHeight,
        maxHeight: MediaQuery.of(context).size.height * maxHeightFraction,
        valueNotifier: heightNotifier,
        builder: (height, percentage) {
          final topPadding = MediaQuery.of(context).padding.top;
          final bottomPadding = MediaQuery.of(context).padding.bottom;

          final double expandedOpacityPercentage = ((percentage - 0.3) / 0.7)
              .clamp(0.0, 1.0);

          if (percentage < 0.3) {
            final double collapsedOpacity =
                1.0 - (percentage / 0.3).clamp(0.0, 1.0);

            return Opacity(
              opacity: collapsedOpacity,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(0),
                ),
                margin: EdgeInsets.all(0),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                elevation: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Hero(
                        tag: 'artwork-${song.id}',
                        child: QueryArtworkWidget(
                          keepOldArtwork: true,
                          artworkBorder: BorderRadius.circular(8),
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget: SizedBox(
                            height: 55,
                            width: 55,
                            child: Card(
                              elevation: 0,
                              child: Icon(FlutterRemix.music_fill),
                            ),
                          ),
                        ),
                      ),

                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(song.artist ?? "${t(context, 'unknown')}"),
                      trailing: IconButton(
                        icon: Icon(
                          provider.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () => provider.isPlaying
                            ? provider.pause()
                            : provider.resume(),
                      ),
                    ),
                    StreamBuilder<Duration>(
                      stream: provider.audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final current = snapshot.data ?? Duration.zero;
                        final total =
                            provider.audioPlayer.duration ?? Duration.zero;
                        final progress = total.inMilliseconds == 0
                            ? 0.0
                            : current.inMilliseconds / total.inMilliseconds;

                        return LinearProgressIndicator(
                          borderRadius: BorderRadius.circular(100),
                          value: progress.clamp(0.0, 1.0),
                          // backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 3,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Opacity(
              opacity: expandedOpacityPercentage,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(106),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                      // gradient: LinearGradient(
                      //   begin: Alignment.topCenter,

                      //   end: Alignment.bottomRight,
                      //   colors: [
                      //     colorScheme.onPrimary, // Starts with the tertiary color
                      //     colorScheme
                      //         .surfaceContainerLowest, // Ends with the primary container color
                      //   ],
                      // ),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: topPadding + 20.0,
                          left: 20.0,
                          right: 20.0,
                          bottom: bottomPadding + 20.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //NowPlaying Bar
                            SizedBox(
                              height: 35,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 15),
                                    child: const Icon(
                                      FlutterRemix.arrow_down_s_fill,
                                    ),
                                  ),
                                  // Expanded(
                                  //   child: Consumer<MusicProvider>(
                                  //     builder: (_, provider, __) {
                                  //       return Text(
                                  //         "Output device: ${provider.connectedDeviceName}",
                                  //       );
                                  //     },
                                  //   ),
                                  // ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        "${t(context, 'now_playing')}",
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 30.0),
                                    child: const SizedBox(),
                                  ),
                                  // IconButton(
                                  //   onPressed: () => _showBottomSheet(context, song),
                                  //   icon: const Icon(FlutterRemix.more_2_fill),
                                  // ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            //Artwork for NowPlaying screen
                            Stack(
                              children: [
                                //ArtWork
                                Hero(
                                  tag: 'artwork-${song.id}',
                                  child: SizedBox(
                                    height: imageSize,
                                    width: imageSize,
                                    child: QueryArtworkWidget(
                                      keepOldArtwork: true,
                                      artworkFit: BoxFit.cover,
                                      quality: 100,

                                      artworkQuality: FilterQuality.high,
                                      artworkBorder: BorderRadius.circular(15),
                                      id: song.id,
                                      type: ArtworkType.AUDIO,
                                      nullArtworkWidget: SizedBox(
                                        height: 55,
                                        width: 55,
                                        child: Card(
                                          elevation: 0,
                                          child: Icon(
                                            FlutterRemix.music_fill,
                                            size: 100,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                //UpComing 1
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Consumer<MusicProvider>(
                                    builder: (context, provider, _) {
                                      final nextSong =
                                          provider.nextSongIfEndingSoon;
                                      if (nextSong == null)
                                        return const SizedBox();

                                      return SizedBox(
                                        width: upcomingSize,
                                        child: Card(
                                          elevation: 0,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 5.0,
                                              horizontal: 5.0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${t(context, 'up_coming')}",
                                                  // ,style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                SizedBox(height: 5.0),
                                                Opacity(
                                                  opacity:
                                                      0.7, // Make the entire Row dim
                                                  child: Row(
                                                    children: [
                                                      QueryArtworkWidget(
                                                        keepOldArtwork: true,

                                                        artworkQuality:
                                                            FilterQuality.high,
                                                        id: nextSong.id,
                                                        type: ArtworkType.AUDIO,
                                                        artworkBorder:
                                                            BorderRadius.circular(
                                                              7.0,
                                                            ),

                                                        nullArtworkWidget: SizedBox(
                                                          height: 55,
                                                          width: 55,
                                                          child: Card(
                                                            elevation: 0,
                                                            child: const Icon(
                                                              Icons.music_note,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              nextSong.title,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            Text(
                                                              nextSong.artist ??
                                                                  "${t(context, 'unknown')}",
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // Hero(
                            //   tag: 'artwork-${song.id}',
                            //   child: provider.getArtworkWidget(
                            //     context,
                            //   ), // Your cached artwork widget
                            // ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.05, // ~20
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                song.artist ?? "${t(context, 'unknown')}",

                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.035, // ~14
                                ),
                              ),
                            ),
                            const SizedBox(height: 50.0),
                            StreamBuilder<Duration>(
                              stream: provider.throttledPositionStream,
                              builder: (context, snapshot) {
                                final current = snapshot.data ?? Duration.zero;
                                final total =
                                    provider.audioPlayer.duration ??
                                    Duration.zero;

                                return Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                        ),
                                        trackHeight: 5.0,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 0,
                                          elevation: 0,
                                        ),
                                        overlayShape:
                                            SliderComponentShape.noOverlay,
                                        thumbColor: Colors.transparent,
                                      ),
                                      child: TweenAnimationBuilder<double>(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        tween: Tween<double>(
                                          begin: 0,
                                          end: current.inSeconds.toDouble(),
                                        ),
                                        builder:
                                            (context, animatedValue, child) {
                                              return Slider(
                                                value: animatedValue,
                                                max: total.inSeconds.toDouble(),
                                                onChanged: (v) => provider.seek(
                                                  Duration(seconds: v.toInt()),
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(formatTime(current)),
                                          Text(formatTime(total)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () => provider.toggleShuffle(),
                                  icon: Icon(
                                    provider.isShuffleOn
                                        ? Icons.shuffle_on_rounded
                                        : Icons.shuffle,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => provider.playPrevious(),
                                  icon: const Icon(FlutterRemix.skip_back_fill),
                                ),
                                IconButton.filled(
                                  iconSize: 30,
                                  icon: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      provider.isPlaying
                                          ? FlutterRemix.pause_fill
                                          : FlutterRemix.play_fill,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (provider.isPlaying) {
                                      provider.pause();
                                    } else {
                                      provider.resume();
                                    }
                                  },
                                ),
                                IconButton(
                                  onPressed: () => provider.playNext(),
                                  icon: const Icon(
                                    FlutterRemix.skip_forward_fill,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => provider.cycleRepeatMode(),
                                  icon: Icon(_repeatIcon(provider.repeatMode)),
                                ),
                              ],
                            ),

                            SizedBox(
                              height: 130,
                            ), // ✅ Add bottom space for padding
                            Flexible(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      child: Text("${t(context, 'more')}"),
                                      onPressed: () =>
                                          _showBottomSheet(context, song),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      child: Text("${t(context, 'lyrics')}"),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LyricsPage(),
                                          ),
                                        );
                                      },

                                      // => _showLyrics(context),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      child: Text(
                                        "${t(context, 'upcoming_list')}",
                                      ),
                                      onPressed: () =>
                                          _showUpComingSongs(context, song),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  IconData _repeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.one:
        return FlutterRemix.repeat_one_fill;
      // case RepeatMode.all:
      //   return Icons.repeat_all;
      default:
        return FlutterRemix.repeat_2_fill;
    }
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  // void _showLyrics(BuildContext context, SongModel song) {
  //   showModalBottomSheet(
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadiusGeometry.circular(15.0),
  //     ),
  //     isDismissible: false,
  //     context: context,
  //     builder: (context) {
  //       return SizedBox(
  //         width: MediaQuery.of(context).size.width / 1.3,

  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(
  //             vertical: 10.0,
  //             horizontal: 15.0,
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 song.title,
  //                 style: Theme.of(context).textTheme.headlineSmall,
  //               ),
  //               Text(
  //                 "Strawberries, cherries and an angel's kiss in spring My summer wine is really made from all these thingsStrawberries, cherries and an angel's kiss in spring My summer wine is really made from all these thingsStrawberries, cherries and an angel's kiss in spring My summer wine is really made from all these things",

  //                 style: Theme.of(context).textTheme.bodyMedium,
  //               ),
  //               SizedBox(height: 5.0),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.end,
  //                 children: [
  //                   FilledButton(
  //                     onPressed: () {
  //                       Navigator.pop(context);
  //                     },
  //                     child: Text("${t(context, 'close')}"),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void _showUpComingSongs(BuildContext context, SongModel song) {
    showModalBottomSheet(
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(15.0),
      ),
      isDismissible: true,
      context: context,
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: SizedBox(
            width: MediaQuery.of(context).size.width / 1.3,

            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 10.0,
              ),

              child: Consumer<MusicProvider>(
                builder: (context, musicProvider, _) {
                  final upcoming = musicProvider.upcomingSongs;
                  return ListView.builder(
                    itemCount: upcoming.length,
                    itemBuilder: (context, index) {
                      final song = upcoming[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(10),
                        ),
                        leading: QueryArtworkWidget(
                          keepOldArtwork: true,
                          artworkBorder: BorderRadius.circular(5.0),
                          id: song.id,
                          artworkQuality: FilterQuality.high,
                          nullArtworkWidget: SizedBox(
                            height: 55,
                            width: 55,
                            child: Card(
                              elevation: 0,

                              child: Icon(FlutterRemix.music_fill),
                            ),
                          ),
                          type: ArtworkType.AUDIO,
                        ),

                        title: Text(
                          song.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist ?? "${t(context, 'unknown')}",
                        ),
                        onTap: () => musicProvider.playSong(song),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBottomSheet(BuildContext context, SongModel song) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        final provider = Provider.of<MusicProvider>(context);
        return SizedBox(
          width: MediaQuery.of(context).size.width / 1.3,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 10.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: const Icon(FlutterRemix.information_fill),
                  title: Text('${t(context, 'song_details')}'),
                  onTap: () {
                    Navigator.pop(context);
                    showDetail(context, song);
                  },
                ),
                const SizedBox(height: 5.0),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: const Icon(FlutterRemix.share_fill),
                  title: Text('${t(context, 'share')}'),
                  onTap: () {
                    provider.shareCurrentSong();
                  },
                ),
                const SizedBox(height: 5.0),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: Icon(
                    provider.isFavorite(song.id)
                        ? FlutterRemix.heart_fill
                        : FlutterRemix.heart_line,
                    color: provider.isFavorite(song.id) ? Colors.red : null,
                  ),
                  title: Text('${t(context, 'favorite')}'),
                  onTap: () => provider.toggleFavorite(song.id),
                ),
                const SizedBox(height: 10.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: Text("${t(context, 'close')}"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showDetail(BuildContext context, SongModel song) async {
    await showDialog(
      context: context,
      builder: (context) {
        return SongDetailsDialog(song: song);
      },
    );
  }
}
