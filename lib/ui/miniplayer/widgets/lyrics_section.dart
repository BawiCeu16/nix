import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/animation_data.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:provider/provider.dart';
import 'package:flutter_remix/flutter_remix.dart';
import '../../widgets/buttons/nix_icon_button.dart';
import '../../widgets/buttons/expressive_button.dart';
import 'package:hive/hive.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/providers/settings_provider.dart';

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
  final Track? track;

  const LyricsSection({
    super.key,
    required this.lyricsAnim,
    required this.data,
    required this.maxOffset,
    required this.topInset,
    required this.track,
  });

  @override
  State<LyricsSection> createState() => _LyricsSectionState();
}

class _LyricsSectionState extends State<LyricsSection> {
  String? _plainLyrics;
  List<LyricLine>? _syncedLyrics;
  bool _isLoading = false;
  int? _fetchedTrackId;
  StreamSubscription<Duration>? _positionSubscription;

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

  void _showManualSearchDialog(BuildContext context, dynamic track) {
    if (track == null) return;

    final titleController = TextEditingController(text: track.title);
    final artistController = TextEditingController(text: track.artist ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return NixDialog(
          title: 'Find Lyrics Manually',
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: artistController,
              decoration: const InputDecoration(labelText: 'Artist'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ExpressiveToneButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ExpressiveButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _performManualSearch(
                        titleController.text.trim(),
                        artistController.text.trim(),
                        track.album,
                        (track.duration) ~/ 1000,
                        track.title,
                        track.artist,
                      );
                    },
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _performManualSearch(
    String title,
    String artist,
    String? album,
    int durationSecs,
    String rawTitle,
    String? rawArtist,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final query = '$title $artist'.trim();
      final queryParams = {'q': query};

      final searchUri = Uri.parse(
        'https://lrclib.net/api/search',
      ).replace(queryParameters: queryParams);
      final searchResponse = await http.get(searchUri);

      if (searchResponse.statusCode == 200) {
        final List searchData = json.decode(searchResponse.body);
        if (searchData.isNotEmpty) {
          if (mounted) {
            final cacheKey = _getCacheKey(rawTitle, rawArtist);
            _showSearchResultsDialog(context, searchData, cacheKey);
          }
        } else {
          setState(() {
            _plainLyrics = "Lyrics not found.";
            _syncedLyrics = null;
          });
        }
      } else {
        setState(() {
          _plainLyrics = "Error fetching lyrics.";
          _syncedLyrics = null;
        });
      }
    } catch (e) {
      setState(() {
        _plainLyrics = "Error fetching lyrics.";
        _syncedLyrics = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSearchResultsDialog(
    BuildContext context,
    List results,
    String cacheKey,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Lyrics'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final trackName = result['trackName'] ?? 'Unknown Track';
                final artistName = result['artistName'] ?? 'Unknown Artist';
                final albumName = result['albumName'] ?? 'Unknown Album';
                final hasSynced =
                    result['syncedLyrics'] != null &&
                    result['syncedLyrics'].toString().isNotEmpty;

                return ListTile(
                  title: Text(trackName),
                  subtitle: Text('$artistName • $albumName'),
                  trailing: hasSynced
                      ? const Icon(FlutterRemix.timer_line, size: 16)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    final settings = context.read<SettingsProvider>();
                    _handleLyricsData(result);
                    if (settings.saveLyricsOffline) {
                      Hive.box(
                        HiveKeys.lyricsBox,
                      ).put(cacheKey, json.encode(result));
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            ExpressiveButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
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

  void _checkAndFetch() {
    final track = widget.track;
    if (track == null) return;

    final cacheKey = _getCacheKey(track.title, track.artist);
    final box = Hive.box(HiveKeys.lyricsBox);

    if (box.containsKey(cacheKey)) {
      if (track.id != _fetchedTrackId) {
        _fetchedTrackId = track.id;
        _fetchLyrics(
          track.title,
          track.artist,
          track.album,
          (track.duration) ~/ 1000,
        );
      }
      return;
    }

    if (widget.lyricsAnim.value > 0 && track.id != _fetchedTrackId) {
      _fetchedTrackId = track.id;
      _fetchLyrics(
        track.title,
        track.artist,
        track.album,
        (track.duration) ~/ 1000,
      );
    }
  }

  void _updatePositionListener() {
    final currentMusic = context.read<CurrentMusicProvider>();
    final isLyricsVisible =
        widget.lyricsAnim.value > 0 && widget.data.bounceClampedProgress > 0;

    if (isLyricsVisible && _syncedLyrics != null) {
      final currentPos = currentMusic.position;
      _updateIndexForPosition(currentPos);

      if (_positionSubscription == null) {
        _positionSubscription = currentMusic.positionStream.listen((pos) {
          if (!mounted || _syncedLyrics == null) return;
          _updateIndexForPosition(pos);
        });
      }
    } else {
      _positionSubscription?.cancel();
      _positionSubscription = null;
    }
  }

  void _updateIndexForPosition(Duration pos) {
    if (_syncedLyrics == null) return;
    int newIndex = -1;
    for (int i = 0; i < _syncedLyrics!.length; i++) {
      if (pos >= _syncedLyrics![i].time) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentIndex && newIndex != -1) {
      setState(() {
        _currentIndex = newIndex;
      });
      if (!_userScrolled && _scrollController.isAttached) {
        _scrollController.scrollTo(
          index: _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.5,
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndFetch();
    _updatePositionListener();
  }

  @override
  void didUpdateWidget(covariant LyricsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track?.id != widget.track?.id ||
        oldWidget.lyricsAnim.value != widget.lyricsAnim.value) {
      _checkAndFetch();
      _updatePositionListener();
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
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

  String _cleanTitle(String title, String? artist) {
    if (artist == null || artist.isEmpty) return title;
    String cleaned = title;

    final lowerTitle = title.toLowerCase();
    final lowerArtist = artist.toLowerCase();

    if (lowerTitle.contains(lowerArtist)) {
      final regex = RegExp(
        r'\s*[-\u2010-\u2015]\s*' +
            RegExp.escape(artist) +
            r'|\s*' +
            RegExp.escape(artist) +
            r'\s*[-\u2010-\u2015]\s*',
        caseSensitive: false,
      );
      if (regex.hasMatch(cleaned)) {
        cleaned = cleaned.replaceAll(regex, '');
      } else {
        final regex2 = RegExp(RegExp.escape(artist), caseSensitive: false);
        cleaned = cleaned.replaceAll(regex2, '').trim();
      }
    }

    cleaned = cleaned.replaceAll(RegExp(r'\(\s*\)'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\[\s*\]'), '').trim();

    return cleaned.isNotEmpty ? cleaned : title;
  }

  String _getCacheKey(String title, String? artist) {
    return "${title.toLowerCase().trim()}_${(artist ?? '').toLowerCase().trim()}";
  }

  Future<void> _fetchLyrics(
    String rawTitle,
    String? artist,
    String? album,
    int durationSecs,
  ) async {
    final title = _cleanTitle(rawTitle, artist);
    final cacheKey = _getCacheKey(rawTitle, artist);
    final box = Hive.box(HiveKeys.lyricsBox);
    final settings = context.read<SettingsProvider>();

    if (box.containsKey(cacheKey)) {
      try {
        final cachedValue = box.get(cacheKey);
        if (cachedValue != null) {
          final Map<String, dynamic> mapData = Map<String, dynamic>.from(
            cachedValue is String ? json.decode(cachedValue) : cachedValue,
          );
          _plainLyrics = null;
          _syncedLyrics = null;
          _currentIndex = -1;
          _isLoading = false;
          _handleLyricsData(mapData);
          return;
        }
      } catch (e) {
        // Fallback to fetch if corrupted
      }
    }

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
        if (settings.saveLyricsOffline) {
          box.put(cacheKey, json.encode(data));
        }
      } else {
        final searchUri = Uri.parse(
          'https://lrclib.net/api/search',
        ).replace(queryParameters: queryParams);
        final searchResponse = await http.get(searchUri);

        if (searchResponse.statusCode == 200) {
          final List searchData = json.decode(searchResponse.body);
          if (searchData.isNotEmpty) {
            _handleLyricsData(searchData.first);
            if (settings.saveLyricsOffline) {
              box.put(cacheKey, json.encode(searchData.first));
            }
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
        _updatePositionListener();
        return;
      }
    }
    setState(() {
      _plainLyrics = data['plainLyrics'] ?? "Lyrics not found.";
    });
    _updatePositionListener();
  }

  @override
  Widget build(BuildContext context) {
    final track = context.select<CurrentMusicProvider, Track?>(
      (p) => p.currentTrack,
    );
    final currentMusic = context.read<CurrentMusicProvider>();

    final topPosition = widget.topInset + 80.0;
    final trackInfoYFromBottom =
        (widget.maxOffset / 3.6) - (140.0 * widget.lyricsAnim.value);
    final bottomPosition = trackInfoYFromBottom + 120.0;

    final isVisible =
        widget.data.bounceClampedProgress > 0 && widget.lyricsAnim.value > 0;

    return Positioned(
      top: topPosition,
      bottom: bottomPosition,
      left: 24.0,
      right: 24.0,
      child: Visibility(
        visible: isVisible,
        maintainState: true,
        child: Opacity(
          opacity: widget.lyricsAnim.value * widget.data.opacity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
            ),
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
                            ? NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification is UserScrollNotification) {
                                    if (notification.direction !=
                                        ScrollDirection.idle) {
                                      if (!_userScrolled) {
                                        setState(() => _userScrolled = true);
                                      }
                                    }
                                  }
                                  return false;
                                },
                                child: ScrollablePositionedList.builder(
                                  itemScrollController: _scrollController,
                                  itemPositionsListener: _itemPositionsListener,
                                  physics: const BouncingScrollPhysics(),
                                  initialScrollIndex: _currentIndex != -1
                                      ? _currentIndex
                                      : 0,
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
                                          setState(() => _userScrolled = false);
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
                              )
                            : SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 50.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _plainLyrics ??
                                          "Lyrics not found for\n${track?.title ?? 'this track'}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        height: 1.8,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ExpressiveButton(
                                      onPressed: () => _showManualSearchDialog(
                                        context,
                                        track,
                                      ),
                                      child: const Text('Find Manually'),
                                    ),
                                  ],
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
      ),
    );
  }
}
