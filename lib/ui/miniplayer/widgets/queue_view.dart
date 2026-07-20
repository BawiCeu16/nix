import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/ui/widgets/buttons/nix_icon_button.dart';
import 'package:nix/ui/widgets/tiles/queue_tile.dart';
import 'package:nix/core/haptic_utils.dart';

class QueueView extends StatefulWidget {
  final double queueProgressValue;
  final double maxOffset;
  final double topInset;
  final ScrollController? controller;
  final VoidCallback? onReorderBegin;
  final VoidCallback? onReorderEnd;

  const QueueView({
    super.key,
    required this.queueProgressValue,
    required this.maxOffset,
    required this.topInset,
    this.controller,
    this.onReorderBegin,
    this.onReorderEnd,
  });

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  bool _showScrollButton = false;
  bool _isPlayerAbove = true;
  int? _lastScrolledTrackId;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_scrollListener);
    // Listen for track changes to auto-scroll if queue is open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CurrentMusicProvider>().addListener(_trackChangeListener);
      }
    });
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_scrollListener);
    // Be careful with context.read in dispose, better to use a stored reference if possible
    // but here the provider is long-lived.
    try {
      context.read<CurrentMusicProvider>().removeListener(_trackChangeListener);
    } catch (_) {}
    super.dispose();
  }

  void _trackChangeListener() {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final currentMusic = context.read<CurrentMusicProvider>();
    final currentTrackId = currentMusic.currentTrack?.id;

    // Only auto-scroll if the track has actually changed to avoid Play/Pause loops
    if (widget.queueProgressValue == 1.0 &&
        settings.autoScrollQueue &&
        currentTrackId != _lastScrolledTrackId) {
      _scrollToCurrentTrack();
    }
  }

  void _scrollListener() {
    if (widget.controller == null || !widget.controller!.hasClients) return;

    final currentMusic = context.read<CurrentMusicProvider>();
    final playing = currentMusic.currentTrack;
    if (playing == null) return;

    final tracks = currentMusic.currentPlaylist?.tracks ?? [];
    final currentIndex = tracks.indexWhere((s) => s.id == playing.id);
    if (currentIndex < 0) return;

    final double itemHeight = 64.0;
    final double headerHeight = 68.0;
    final double viewportHeight = widget.controller!.position.viewportDimension;

    final currentScroll = widget.controller!.offset;
    final itemPosition = (currentIndex * itemHeight) + headerHeight;

    // Show button if playing item is off-screen
    // Off-screen is when itemPosition < scroll (above) or itemPosition > scroll + viewport (below)
    final bool isAbove = itemPosition < currentScroll - (itemHeight / 2);
    final bool isBelow =
        itemPosition > currentScroll + viewportHeight - (itemHeight / 2);
    final bool shouldShow = isAbove || isBelow;

    if (shouldShow != _showScrollButton || isAbove != _isPlayerAbove) {
      setState(() {
        _showScrollButton = shouldShow;
        _isPlayerAbove = isAbove;
      });
    }
  }

  @override
  void didUpdateWidget(covariant QueueView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_scrollListener);
      widget.controller?.addListener(_scrollListener);
    }

    final settings = context.read<SettingsProvider>();
    if (widget.queueProgressValue == 1.0 &&
        oldWidget.queueProgressValue < 1.0 &&
        settings.autoScrollQueue) {
      // Use PostFrameCallback to ensure the CustomScrollView has attached the controller
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToCurrentTrack();
      });
    }
  }

  void _scrollToCurrentTrack() {
    if (widget.queueProgressValue < 1.0) return;
    if (widget.controller == null || !widget.controller!.hasClients) return;

    final currentMusic = context.read<CurrentMusicProvider>();
    final playing = currentMusic.currentTrack;
    if (playing == null) return;

    final tracks = currentMusic.currentPlaylist?.tracks ?? [];
    final currentIndex = tracks.indexWhere((s) => s.id == playing.id);

    if (currentIndex >= 0) {
      final double itemHeight = 64.0;
      final double headerInitialPadding = 16.0;
      final double headerContentHeight = 40.0;
      final double headerBottomPadding = 12.0;
      final double headerHeight =
          headerInitialPadding + headerContentHeight + headerBottomPadding;

      final double viewportHeight =
          widget.controller!.position.viewportDimension;

      // Calculate target to center the item
      double targetOffset =
          (currentIndex * itemHeight) +
          headerHeight -
          (viewportHeight / 2) +
          (itemHeight / 2);

      // Clamp the offset
      targetOffset = targetOffset.clamp(
        0.0,
        widget.controller!.position.maxScrollExtent,
      );

      _lastScrolledTrackId = playing.id;
      widget.controller?.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _reorderItemCallback(int oldIndex, int newIndex) {
    final settings = context.read<SettingsProvider>();
    final currentMusic = context.read<CurrentMusicProvider>();
    currentMusic.reorderQueue(oldIndex, newIndex);
    HapticUtils.trigger(settings);
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.select<CurrentMusicProvider, Playlist?>(
      (p) => p.currentPlaylist,
    );
    final currentTrack = context.select<CurrentMusicProvider, Track?>(
      (p) => p.currentTrack,
    );
    final currentMusic = context.read<CurrentMusicProvider>();
    final tracks = playlist?.tracks ?? [];

    return Transform.translate(
      offset: Offset(0, (1 - widget.queueProgressValue) * widget.maxOffset),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(top: widget.topInset + 60),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Column(
                children: [
                  // Drag Handle Pill
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: .4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        CustomScrollView(
                          scrollCacheExtent: const .pixels(1000.0),
                          controller: widget.controller,
                          physics: widget.queueProgressValue == 1.0
                              ? const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                )
                              : const NeverScrollableScrollPhysics(),
                          slivers: [
                            // Properly Styled Header
                            SliverPadding(
                              padding: const EdgeInsets.only(
                                left: 24.0,
                                top: 16.0,
                                bottom: 12.0,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Row(
                                  children: [
                                    Text(
                                      "Queue",
                                      style: TextStyle(
                                        fontSize: 22.0,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    // ExpressiveToneButton(
                                    //   onPressed: () {
                                    //     currentMusic.shuffleQueue();
                                    //     HapticUtils.trigger(settings);
                                    //   },
                                    //   padding: const EdgeInsets.symmetric(
                                    //     horizontal: 12,
                                    //     vertical: 8,
                                    //   ),
                                    //   child: const Row(
                                    //     mainAxisSize: MainAxisSize.min,
                                    //     children: [
                                    //       Icon(
                                    //         FlutterRemix.shuffle_line,
                                    //         size: 16,
                                    //       ),
                                    //       SizedBox(width: 6),
                                    //       Text(
                                    //         "Shuffle",
                                    //         style: TextStyle(fontSize: 12),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                    // const SizedBox(width: 8),
                                    // ExpressiveToneButton(
                                    //   onPressed: () {
                                    //     currentMusic.clearQueue();
                                    //     HapticUtils.trigger(settings);
                                    //   },
                                    //   padding: const EdgeInsets.symmetric(
                                    //     horizontal: 12,
                                    //     vertical: 8,
                                    //   ),
                                    //   child: const Row(
                                    //     mainAxisSize: MainAxisSize.min,
                                    //     children: [
                                    //       Icon(
                                    //         FlutterRemix.delete_bin_line,
                                    //         size: 16,
                                    //       ),
                                    //       SizedBox(width: 6),
                                    //       Text(
                                    //         "Clear",
                                    //         style: TextStyle(fontSize: 12),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                    // const SizedBox(width: 24),
                                  ],
                                ),
                              ),
                            ),
                            SliverReorderableList(
                              itemCount: tracks.length,
                              onReorderItem: _reorderItemCallback,
                              proxyDecorator: (child, index, animation) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, child) {
                                    final double animValue = Curves.easeInOut
                                        .transform(animation.value);
                                    final double scale =
                                        1.0 + (0.05 * animValue);
                                    return Transform.scale(
                                      scale: scale,
                                      child: Material(
                                        elevation: 10,
                                        shadowColor: Colors.black.withValues(
                                          alpha: 0.2 * animValue,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(
                                              alpha: 0.95 * animValue,
                                            ),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: child,
                                );
                              },
                              itemBuilder: (context, index) {
                                final track = tracks[index];
                                return QueueTile(
                                  key: ValueKey('queue_${track.id}_$index'),
                                  title: track.title,
                                  subtitle: track.artist,
                                  trackId: track.id,
                                  itemIndex: index,
                                  isPlaying: currentTrack?.id == track.id,
                                  onTap: () {
                                    currentMusic.playTrack(
                                      track,
                                      playlist: playlist,
                                    );
                                    HapticUtils.selection(
                                      context.read<SettingsProvider>(),
                                    );
                                  },
                                  onRemove: () {
                                    currentMusic.removeFromQueue(index);
                                  },
                                  trailing: Listener(
                                    onPointerDown: (_) =>
                                        widget.onReorderBegin?.call(),
                                    onPointerUp: (_) =>
                                        widget.onReorderEnd?.call(),
                                    onPointerCancel: (_) =>
                                        widget.onReorderEnd?.call(),
                                    child: ReorderableDragStartListener(
                                      index: index,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          FlutterRemix.menu_line,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SliverPadding(
                              padding: EdgeInsets.only(bottom: 100),
                            ),
                          ],
                        ),
                        // Floating Scroll to Playing Button
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedSlide(
                              offset: _showScrollButton
                                  ? Offset.zero
                                  : const Offset(0, 1),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              child: AnimatedOpacity(
                                opacity: _showScrollButton ? 1.0 : 0.0,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
