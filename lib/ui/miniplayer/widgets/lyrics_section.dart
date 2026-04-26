import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/animation_data.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_remix/flutter_remix.dart';
import '../../widgets/buttons/nix_icon_button.dart';

class LyricLine {
  final Duration time;
  final String text;

  LyricLine(this.time, this.text);
}

class LyricsSection extends StatefulWidget {
  final Animation<double> lyricsAnim;
  final PlayerAnimationData data;
  final double maxOffset;
  final double topInset;

  const LyricsSection({
    super.key,
    required this.lyricsAnim,
    required this.data,
    required this.maxOffset,
    required this.topInset,
  });

  @override
  State<LyricsSection> createState() => _LyricsSectionState();
}

class _LyricsSectionState extends State<LyricsSection> {
  String? _plainLyrics;
  List<LyricLine>? _syncedLyrics;
  bool _isLoading = false;
  int? _currentTrackId;

  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int _currentIndex = -1;
  bool _userScrolled = false;
  bool _isPlayerAbove = true;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(() {
      if (!_userScrolled || _currentIndex == -1) return;
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;

      int firstVisible = positions.first.index;
      int lastVisible = positions.first.index;
      for (var p in positions) {
        if (p.index < firstVisible) firstVisible = p.index;
        if (p.index > lastVisible) lastVisible = p.index;
      }

      // Current lyric is above viewport → show arrow up
      // Current lyric is below viewport → show arrow down
      final bool isAbove = _currentIndex < firstVisible;

      if (_isPlayerAbove != isAbove) {
        setState(() {
          _isPlayerAbove = isAbove;
        });
      }
    });
  }

  void _scrollToCurrentTrack() {
    setState(() => _userScrolled = false);
    if (_scrollController.isAttached && _currentIndex != -1) {
      _scrollController.scrollTo(
        index: _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.5,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentMusic = context.watch<CurrentMusicProvider>();
    final track = currentMusic.currentTrack;

    if (track != null && track.id != _currentTrackId) {
      _currentTrackId = track.id;
      _fetchLyrics(
        track.title,
        track.artist,
        track.album,
        (track.duration) ~/ 1000,
      );
    }
  }

  List<LyricLine> _parseLrc(String lrc) {
    final lines = lrc.split('\n');
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    List<LyricLine> parsedLines = [];

    for (var line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        int milliseconds = int.parse(match.group(3)!);
        if (match.group(3)!.length == 2) {
          milliseconds *= 10;
        }

        final text = match.group(4)!.trim();
        if (text.isNotEmpty) {
          parsedLines.add(
            LyricLine(
              Duration(
                minutes: minutes,
                seconds: seconds,
                milliseconds: milliseconds,
              ),
              text,
            ),
          );
        }
      }
    }
    return parsedLines;
  }

  Future<void> _fetchLyrics(
    String title,
    String? artist,
    String? album,
    int durationSecs,
  ) async {
    setState(() {
      _isLoading = true;
      _plainLyrics = null;
      _syncedLyrics = null;
      _currentIndex = -1;
    });

    try {
      final queryParams = {
        'track_name': title,
        'artist_name': artist ?? '',
        'album_name': album ?? '',
        'duration': durationSecs.toString(),
      };

      final uri = Uri.parse(
        'https://lrclib.net/api/get',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _handleLyricsData(data);
      } else {
        final searchUri = Uri.parse(
          'https://lrclib.net/api/search',
        ).replace(queryParameters: queryParams);
        final searchResponse = await http.get(searchUri);

        if (searchResponse.statusCode == 200) {
          final List searchData = json.decode(searchResponse.body);
          if (searchData.isNotEmpty) {
            _handleLyricsData(searchData.first);
          } else {
            setState(() {
              _plainLyrics = "Lyrics not found.";
            });
          }
        } else {
          setState(() {
            _plainLyrics = "Lyrics not found.";
          });
        }
      }
    } catch (e) {
      setState(() {
        _plainLyrics = "Error fetching lyrics.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleLyricsData(Map<String, dynamic> data) {
    if (data['syncedLyrics'] != null &&
        data['syncedLyrics'].toString().isNotEmpty) {
      final parsed = _parseLrc(data['syncedLyrics']);
      if (parsed.isNotEmpty) {
        setState(() {
          _syncedLyrics = parsed;
        });
        return;
      }
    }
    setState(() {
      _plainLyrics = data['plainLyrics'] ?? "Lyrics not found.";
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.bounceClampedProgress == 0 ||
        widget.lyricsAnim.value == 0) {
      return const SizedBox.shrink();
    }

    final currentMusic = context.watch<CurrentMusicProvider>();
    final track = currentMusic.currentTrack;

    final topPosition = widget.topInset + 80.0;
    final trackInfoYFromBottom =
        (widget.maxOffset / 3.6) - (140.0 * widget.lyricsAnim.value);
    final bottomPosition = trackInfoYFromBottom + 120.0;

    return Positioned(
      top: topPosition,
      bottom: bottomPosition,
      left: 24.0,
      right: 24.0,
      child: Opacity(
        opacity: widget.lyricsAnim.value * widget.data.opacity,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24.0)),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24.0),
                child: ShaderMask(
                  shaderCallback: (Rect rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.15, 0.85, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Center(
                      child: _isLoading
                          ? const LoadingIndicatorM3E()
                          : _syncedLyrics != null
                          ? StreamBuilder<Duration>(
                              stream: currentMusic.positionStream,
                              builder: (context, snapshot) {
                                final pos =
                                    snapshot.data ?? currentMusic.position;

                                int newIndex = -1;
                                for (
                                  int i = 0;
                                  i < _syncedLyrics!.length;
                                  i++
                                ) {
                                  if (pos >= _syncedLyrics![i].time) {
                                    newIndex = i;
                                  } else {
                                    break;
                                  }
                                }

                                if (newIndex != _currentIndex &&
                                    newIndex != -1) {
                                  _currentIndex = newIndex;
                                  if (!_userScrolled &&
                                      _scrollController.isAttached) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (_scrollController.isAttached &&
                                              !_userScrolled) {
                                            _scrollController.scrollTo(
                                              index: _currentIndex,
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeOut,
                                              alignment: 0.5,
                                            );
                                          }
                                        });
                                  }
                                }

                                return NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification
                                        is UserScrollNotification) {
                                      if (notification.direction !=
                                          ScrollDirection.idle) {
                                        if (!_userScrolled)
                                          setState(() => _userScrolled = true);
                                      }
                                    }
                                    return false;
                                  },
                                  child: ScrollablePositionedList.builder(
                                    itemScrollController: _scrollController,
                                    itemPositionsListener:
                                        _itemPositionsListener,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 200.0,
                                    ),
                                    itemCount: _syncedLyrics!.length,
                                    itemBuilder: (context, index) {
                                      final isCurrent = index == _currentIndex;
                                      return AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        style: TextStyle(
                                          fontSize: isCurrent ? 24.0 : 20.0,
                                          height: 1.8,
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isCurrent
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            currentMusic.seek(
                                              _syncedLyrics![index].time,
                                            );
                                            setState(
                                              () => _userScrolled = false,
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                            ),
                                            child: Text(
                                              _syncedLyrics![index].text,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            )
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                vertical: 50.0,
                              ),
                              child: Text(
                                _plainLyrics ??
                                    "Lyrics not found for\n${track?.title ?? 'this track'}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18.0,
                                  height: 1.8,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedSlide(
                    offset: _userScrolled ? Offset.zero : const Offset(0, 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: _userScrolled ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: NixIconButton(
                        onPressed: _scrollToCurrentTrack,
                        icon: Icon(
                          _isPlayerAbove
                              ? FlutterRemix.arrow_up_line
                              : FlutterRemix.arrow_down_line,
                        ),
                        tooltip: 'Scroll to playing',
                        size: 52,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
