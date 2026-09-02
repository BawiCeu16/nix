import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/ui/widgets/tiles/track_tile.dart';
import 'package:nix/core/haptic_utils.dart';
import 'package:m3e_floating_toolbar/m3e_floating_toolbar.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';

class QueueView extends StatefulWidget {
  final double queueProgressValue;
  final double maxOffset;
  final double topInset;
  final ScrollController? controller;
  final VoidCallback? onReorderBegin;
  final VoidCallback? onReorderEnd;
  final VoidCallback? onClose;

  const QueueView({
    super.key,
    required this.queueProgressValue,
    required this.maxOffset,
    required this.topInset,
    this.controller,
    this.onReorderBegin,
    this.onReorderEnd,
    this.onClose,
  });

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  bool _showScrollButton = false;
  bool _isPlayerAbove = true;
  int? _lastScrolledTrackId;
  bool _isQueueLocked = true;
  bool _isToolbarExpanded = false;

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
    if (widget.controller == null ||
        !widget.controller!.hasClients ||
        !widget.controller!.position.hasContentDimensions) {
      return;
    }

    final currentMusic = context.read<CurrentMusicProvider>();
    final playing = currentMusic.currentTrack;
    if (playing == null) return;

    final tracks = currentMusic.currentPlaylist?.tracks ?? [];
    final currentIndex = tracks.indexWhere((s) => s.id == playing.id);
    if (currentIndex < 0) return;

    const double itemTileHeight = 76.5;
    const double headerHeight = 38.4;
    final double viewportHeight = widget.controller!.position.viewportDimension;

    final currentScroll = widget.controller!.offset;
    final itemTop = (currentIndex * itemTileHeight) + headerHeight;
    final itemBottom = itemTop + itemTileHeight;

    // Show button if playing item is off-screen
    final bool isAbove = itemBottom < currentScroll + (itemTileHeight / 2);
    final bool isBelow =
        itemTop > currentScroll + viewportHeight - (itemTileHeight / 2);
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
    if (widget.controller == null ||
        !widget.controller!.hasClients ||
        !widget.controller!.position.hasContentDimensions) {
      return;
    }

    final currentMusic = context.read<CurrentMusicProvider>();
    final playing = currentMusic.currentTrack;
    if (playing == null) return;

    final tracks = currentMusic.currentPlaylist?.tracks ?? [];
    final currentIndex = tracks.indexWhere((s) => s.id == playing.id);

    if (currentIndex >= 0) {
      const double itemTileHeight = 76.5;
      const double headerHeight = 38.4;

      final double viewportHeight =
          widget.controller!.position.viewportDimension;

      // Calculate target to position current playing track in exact center of viewport
      final double itemTop = (currentIndex * itemTileHeight) + headerHeight;
      final double itemCenter = itemTop + (itemTileHeight / 2);

      double targetOffset = itemCenter - (viewportHeight / 2);

      // Clamp offset safely within valid scroll bounds [0, maxScrollExtent]
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
    final currentMusic = context.read<CurrentMusicProvider>();
    final tracks = playlist?.tracks ?? [];

    final double clampedProgress = widget.queueProgressValue.clamp(0.0, 1.0);
    final bool isOffstage = clampedProgress <= 0.0;
    final double opacity = Curves.easeOutCubic.transform(clampedProgress);

    return Offstage(
      offstage: isOffstage,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
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
                child: RepaintBoundary(
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: .4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              M3EFloatingToolbarVerticalNestedScroll(
                                expanded: _isToolbarExpanded,
                                onExpand: () =>
                                    setState(() => _isToolbarExpanded = true),
                                onCollapse: () =>
                                    setState(() => _isToolbarExpanded = false),
                                child: NixScrollbar(
                                  controller: widget.controller,
                                  child: CustomScrollView(
                                    scrollCacheExtent: const .pixels(1000.0),
                                    controller: widget.controller,
                                    physics: widget.queueProgressValue == 1.0
                                        ? const BouncingScrollPhysics(
                                            parent:
                                                AlwaysScrollableScrollPhysics(),
                                          )
                                        : const NeverScrollableScrollPhysics(),
                                    slivers: [
                                      // Properly Styled Header
                                      SliverPadding(
                                        padding: const EdgeInsets.only(
                                          left: 24.0,
                                          top: 0.0,
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
                                            ],
                                          ),
                                        ),
                                      ),
                                      SliverPadding(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                          right: 16,
                                          bottom: 16,
                                        ),
                                        sliver: SliverReorderableList(
                                          itemCount: tracks.length,
                                          onReorderItem: _reorderItemCallback,
                                          proxyDecorator: (child, index, animation) {
                                            return AnimatedBuilder(
                                              animation: animation,
                                              builder: (context, child) {
                                                final double animValue = Curves
                                                    .easeInOut
                                                    .transform(animation.value);
                                                final double scale =
                                                    1.0 + (0.05 * animValue);
                                                return Transform.scale(
                                                  scale: scale,
                                                  child: Material(
                                                    elevation: 10,
                                                    shadowColor: Colors.black
                                                        .withValues(
                                                          alpha:
                                                              0.2 * animValue,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest
                                                        .withValues(
                                                          alpha:
                                                              0.95 * animValue,
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
                                            return Dismissible(
                                              key: ValueKey(
                                                'dismiss_queue_${track.id}_$index',
                                              ),
                                              direction:
                                                  DismissDirection.endToStart,
                                              background: Container(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer,
                                                alignment:
                                                    Alignment.centerRight,
                                                padding: const EdgeInsets.only(
                                                  right: 24.0,
                                                ),
                                                child: Icon(
                                                  FlutterRemix.delete_bin_line,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onErrorContainer,
                                                ),
                                              ),
                                              onDismissed: (direction) {
                                                currentMusic.removeFromQueue(
                                                  index,
                                                );
                                              },
                                              child: TrackTile(
                                                isFirst: index == 0,
                                                isLast:
                                                    index == tracks.length - 1,
                                                track: track,
                                                onPressed: () {
                                                  currentMusic.playTrack(
                                                    track,
                                                    playlist: playlist,
                                                  );
                                                  HapticUtils.selection(
                                                    context
                                                        .read<
                                                          SettingsProvider
                                                        >(),
                                                  );
                                                },
                                                trailing: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 250,
                                                  ),
                                                  switchInCurve:
                                                      Curves.easeOutCubic,
                                                  switchOutCurve:
                                                      Curves.easeInCubic,
                                                  transitionBuilder:
                                                      (child, animation) {
                                                        return FadeTransition(
                                                          opacity: animation,
                                                          child: SizeTransition(
                                                            sizeFactor:
                                                                animation,
                                                            axis:
                                                                Axis.horizontal,
                                                            alignment: Alignment
                                                                .centerRight,
                                                            child: child,
                                                          ),
                                                        );
                                                      },
                                                  child: _isQueueLocked
                                                      ? const SizedBox.shrink(
                                                          key: ValueKey(
                                                            'locked',
                                                          ),
                                                        )
                                                      : Listener(
                                                          key: const ValueKey(
                                                            'unlocked',
                                                          ),
                                                          onPointerDown: (_) =>
                                                              widget
                                                                  .onReorderBegin
                                                                  ?.call(),
                                                          onPointerUp: (_) =>
                                                              widget
                                                                  .onReorderEnd
                                                                  ?.call(),
                                                          onPointerCancel:
                                                              (_) => widget
                                                                  .onReorderEnd
                                                                  ?.call(),
                                                          child: ReorderableDragStartListener(
                                                            index: index,
                                                            child: SizedBox(
                                                              width: 48,
                                                              height: 48,
                                                              child: Center(
                                                                child: Icon(
                                                                  FlutterRemix
                                                                      .menu_line,
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).colorScheme.onSurfaceVariant,
                                                                  size: 20,
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
                                      ),
                                      const SliverPadding(
                                        padding: EdgeInsets.only(bottom: 100),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Floating Toolbar
                              Positioned(
                                bottom: 24,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: M3EHorizontalFloatingToolbar(
                                    expanded: _isToolbarExpanded,
                                    tooltip: 'Queue Options',
                                    decoration: M3EFloatingToolbarDecoration(
                                      colors: M3EFloatingToolbarColors(
                                        toolbarContainerColor: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        toolbarContentColor: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fabContainerColor: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        fabContentColor: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    content: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _isQueueLocked = !_isQueueLocked;
                                            });
                                          },
                                          icon: Icon(
                                            _isQueueLocked
                                                ? FlutterRemix.lock_line
                                                : FlutterRemix.lock_unlock_line,
                                          ),
                                          tooltip: _isQueueLocked
                                              ? 'Unlock Queue'
                                              : 'Lock Queue',
                                        ),

                                        AnimatedSize(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeOutBack,
                                          child: _showScrollButton
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 8.0,
                                                      ),
                                                  child: IconButton(
                                                    alignment: Alignment.center,
                                                    onPressed:
                                                        _scrollToCurrentTrack,
                                                    icon: Icon(
                                                      _isPlayerAbove
                                                          ? FlutterRemix
                                                                .arrow_up_line
                                                          : FlutterRemix
                                                                .arrow_down_line,
                                                    ),
                                                    tooltip:
                                                        'Scroll to playing',
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              widget.onClose?.call(),
                                          icon: const Icon(
                                            FlutterRemix.arrow_down_s_line,
                                          ),
                                          tooltip: 'Close Queue',
                                        ),
                                      ],
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
          ),
        ),
      ),
    );
  }
}
