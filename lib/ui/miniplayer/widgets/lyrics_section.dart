import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/animation_data.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/lyrics_provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:provider/provider.dart';
import 'package:flutter_remix/flutter_remix.dart';
import '../../widgets/buttons/nix_icon_button.dart';
import '../../widgets/buttons/expressive_button.dart';

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
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  LyricsProvider? _lyricsProvider;
  int _lastScrolledIndex = -1;
  bool _userScrolled = false;
  bool _isPlayerAbove = true;

  @override
  void initState() {
    super.initState();
    widget.lyricsAnim.addListener(_onLyricsAnimChanged);
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _onLyricsAnimChanged();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProvider = Provider.of<LyricsProvider>(context);
    if (_lyricsProvider != newProvider) {
      _lyricsProvider?.removeListener(_onLyricsProviderChanged);
      _lyricsProvider = newProvider;
      _lyricsProvider?.addListener(_onLyricsProviderChanged);
    }
  }

  @override
  void didUpdateWidget(covariant LyricsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyricsAnim != widget.lyricsAnim) {
      oldWidget.lyricsAnim.removeListener(_onLyricsAnimChanged);
      widget.lyricsAnim.addListener(_onLyricsAnimChanged);
    }
    _onLyricsAnimChanged();
  }

  @override
  void dispose() {
    _lyricsProvider?.removeListener(_onLyricsProviderChanged);
    widget.lyricsAnim.removeListener(_onLyricsAnimChanged);
    _itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    super.dispose();
  }

  void _onLyricsAnimChanged() {
    if (!mounted) return;
    final lyricsProvider = context.read<LyricsProvider>();
    final isLyricsVisible =
        widget.lyricsAnim.value > 0 && widget.data.bounceClampedProgress > 0;
    lyricsProvider.setActiveSync(isLyricsVisible);
  }

  void _onLyricsProviderChanged() {
    final provider = _lyricsProvider;
    if (provider == null) return;

    final currentIndex = provider.currentIndex;
    if (currentIndex != _lastScrolledIndex && currentIndex != -1) {
      _lastScrolledIndex = currentIndex;
      if (!_userScrolled && _scrollController.isAttached) {
        _scrollController.scrollTo(
          index: currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.5,
        );
      }
    }
  }

  void _onItemPositionsChanged() {
    final provider = _lyricsProvider;
    if (provider == null || !_userScrolled || provider.currentIndex == -1) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    int firstVisible = positions.first.index;
    int lastVisible = positions.first.index;
    for (var p in positions) {
      if (p.index < firstVisible) firstVisible = p.index;
      if (p.index > lastVisible) lastVisible = p.index;
    }

    final bool isAbove = provider.currentIndex < firstVisible;

    if (_isPlayerAbove != isAbove) {
      setState(() {
        _isPlayerAbove = isAbove;
      });
    }
  }

  void _scrollToCurrentTrack() {
    setState(() => _userScrolled = false);
    final provider = _lyricsProvider;
    if (provider != null &&
        _scrollController.isAttached &&
        provider.currentIndex != -1) {
      _scrollController.scrollTo(
        index: provider.currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.5,
      );
    }
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
                        track,
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
    dynamic track,
  ) async {
    final lyricsProvider = context.read<LyricsProvider>();
    final results = await lyricsProvider.searchLyrics(title, artist);

    if (!mounted) return;
    if (results != null && results.isNotEmpty) {
      final cacheKey = lyricsProvider.getCacheKey(track.title, track.artist);
      _showSearchResultsDialog(context, results, cacheKey);
    } else {
      lyricsProvider.setLyricsNotFound();
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
                    context
                        .read<LyricsProvider>()
                        .selectManualLyrics(result, cacheKey);
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

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final currentMusic = context.read<CurrentMusicProvider>();
    final lyricsProvider = context.watch<LyricsProvider>();

    final isLoading = lyricsProvider.isLoading;
    final syncedLyrics = lyricsProvider.syncedLyrics;
    final plainLyrics = lyricsProvider.plainLyrics;
    final currentIndex = lyricsProvider.currentIndex;

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
                        child: isLoading
                            ? const LoadingIndicatorM3E()
                            : syncedLyrics != null
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
                                      itemPositionsListener:
                                          _itemPositionsListener,
                                      physics: const BouncingScrollPhysics(),
                                      initialScrollIndex: currentIndex != -1
                                          ? currentIndex
                                          : 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 200.0,
                                      ),
                                      itemCount: syncedLyrics.length,
                                      itemBuilder: (context, index) {
                                        final isCurrent = index == currentIndex;
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
                                                syncedLyrics[index].time,
                                              );
                                              setState(
                                                  () => _userScrolled = false);
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 4.0,
                                              ),
                                              child: Text(
                                                syncedLyrics[index].text,
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
                                          plainLyrics ??
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
                                          onPressed: () =>
                                              _showManualSearchDialog(
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
