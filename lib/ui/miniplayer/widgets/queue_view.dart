import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/core/motion.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/tiles/m3e_track_tile.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nix/core/haptic_utils.dart';
import 'package:m3e_floating_toolbar/m3e_floating_toolbar.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/core/format.dart';

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
  bool _isQueueLocked = false;
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

    const double itemTileHeight = 74.0;
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
      const double itemTileHeight = 74.0;
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
        duration: NixDurations.medium,
        curve: NixCurves.expressiveDecelerated,
      );
    }
  }

  void _reorderItemCallback(int oldIndex, int newIndex) {
    int target = newIndex;
    if (oldIndex < newIndex) {
      target -= 1;
    }
    final settings = context.read<SettingsProvider>();
    final currentMusic = context.read<CurrentMusicProvider>();
    currentMusic.reorderQueue(oldIndex, target);
    HapticUtils.trigger(settings);
  }

  @override
  Widget build(BuildContext context) {
    final currentMusic = context.watch<CurrentMusicProvider>();
    final playlist = currentMusic.currentPlaylist;
    final showResume = context.select<SettingsProvider, bool>(
      (s) => s.resumeFromPlayedDuration,
    );
    final tracks = playlist?.tracks ?? [];
    final playingIndex = tracks.indexWhere(
      (t) => t.id == currentMusic.currentTrack?.id,
    );
    final selectedIndices = playingIndex != -1 ? {playingIndex} : <int>{};

    final double clampedProgress = widget.queueProgressValue.clamp(0.0, 1.0);
    final bool isOffstage = clampedProgress <= 0.0;

    return Offstage(
      offstage: isOffstage,
      child: Transform.translate(
        offset: Offset(0, (1 - clampedProgress) * widget.maxOffset),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(top: widget.topInset + 60),
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Column(
                    children: [
                      // Drag Handle Pill
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: .4),
                            borderRadius: BorderRadius.circular(100.0),
                          ),
                        ),
                      ),
                      // Scrollable List container
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            M3EFloatingToolbarVerticalNestedScroll(
                              expanded: _isToolbarExpanded,
                              onExpand: () =>
                                  setState(() => _isToolbarExpanded = true),
                              onCollapse: () =>
                                  setState(() => _isToolbarExpanded = false),
                              child: NixScrollbar(
                                controller: widget.controller,
                                // Material 3 Expressive Segmented List with Decoration
                                child: M3EReorderableSegmentedList.builder(
                                  controller: widget.controller,
                                  physics: widget.queueProgressValue == 1.0
                                      ? const BouncingScrollPhysics(
                                          parent:
                                              AlwaysScrollableScrollPhysics(),
                                        )
                                      : const NeverScrollableScrollPhysics(),
                                  header: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 24.0,
                                      top: 8.0,
                                      bottom: 12.0,
                                    ),
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
                                  footer: const SizedBox(height: 100),
                                  keyBuilder: (index) =>
                                      ValueKey(tracks[index].id),
                                  itemCount: tracks.length,
                                  buildDefaultDragHandles: false,
                                  selectionMode: M3ESelectionMode.single,
                                  selectionTrigger: M3ESelectionTrigger.tap,
                                  selectedIndices: selectedIndices,
                                  onSelectionChanged: (set) {
                                    if (set.isNotEmpty &&
                                        set.first < tracks.length) {
                                      currentMusic.playTrack(
                                        tracks[set.first],
                                        playlist: playlist,
                                      );
                                      HapticUtils.selection(
                                        context.read<SettingsProvider>(),
                                      );
                                    }
                                  },
                                  showSelectionCheckmark: false,
                                  decoration: M3ESegmentedListDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    selectedColor: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    outerRadius: 16.0,
                                    innerRadius: 5.0,
                                    pressedRadius: 100.0,
                                    pressedScale: 0.98,
                                    hoveredRadius: 16.0,
                                    selectedRadius: 100.0,
                                    dragRadius: 16.0,
                                    dragElevation: 10.0,
                                    dragScale: 1.00,
                                    gap: 2.5,
                                    padding: EdgeInsets.zero,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 4.0,
                                    ),
                                  ),
                                  onTap: (index) {
                                    currentMusic.playTrack(
                                      tracks[index],
                                      playlist: playlist,
                                    );
                                    HapticUtils.selection(
                                      context.read<SettingsProvider>(),
                                    );
                                  },
                                  onReorder: (oldIndex, newIndex) {
                                    if (_isQueueLocked) return;
                                    widget.onReorderEnd?.call();
                                    _reorderItemCallback(oldIndex, newIndex);
                                  },
                                  itemBuilder: (itemContext, index) {
                                    final track = tracks[index];
                                    final isNowPlaying =
                                        currentMusic.currentTrack?.id ==
                                        track.id;
                                    final colorScheme = Theme.of(
                                      itemContext,
                                    ).colorScheme;

                                    return Dismissible(
                                      key: ValueKey(
                                        'dismiss_queue_${track.id}_${identityHashCode(track)}',
                                      ),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        color: colorScheme.errorContainer,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 24.0,
                                        ),
                                        child: Icon(
                                          FlutterRemix.delete_bin_line,
                                          color: colorScheme.onErrorContainer,
                                        ),
                                      ),
                                      onDismissed: (direction) {
                                        currentMusic.removeFromQueue(index);
                                      },
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 72.0,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 10.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _ItemDragInterceptor(
                                                  child: Row(
                                                    children: [
                                                      M3EArtworkLeading(
                                                        trackId: track.id,
                                                        isPlaying: isNowPlaying,
                                                      ),
                                                      const SizedBox(
                                                        width: 12.0,
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              track.title,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    isNowPlaying
                                                                    ? FontWeight
                                                                          .bold
                                                                    : FontWeight
                                                                          .w500,
                                                                color:
                                                                    isNowPlaying
                                                                    ? colorScheme
                                                                          .onPrimaryContainer
                                                                    : colorScheme
                                                                          .onSurface,
                                                              ),
                                                            ),
                                                            ValueListenableBuilder<
                                                              Box<int>
                                                            >(
                                                              valueListenable:
                                                                  Hive.box<int>(
                                                                    HiveKeys
                                                                        .trackPositionsBox,
                                                                  ).listenable(
                                                                    keys: [
                                                                      track.id,
                                                                    ],
                                                                  ),
                                                              builder: (context, box, _) {
                                                                final savedMs =
                                                                    showResume
                                                                    ? box.get(
                                                                        track
                                                                            .id,
                                                                      )
                                                                    : null;
                                                                final totalDurationStr = Duration(
                                                                  milliseconds:
                                                                      track
                                                                          .duration,
                                                                ).shortFormat();
                                                                final durationStr =
                                                                    savedMs !=
                                                                        null
                                                                    ? '${Duration(milliseconds: savedMs).shortFormat()} / $totalDurationStr'
                                                                    : totalDurationStr;

                                                                return Text(
                                                                  '${track.artist} · $durationStr',
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color:
                                                                        isNowPlaying
                                                                        ? colorScheme.onPrimaryContainer.withValues(
                                                                            alpha:
                                                                                0.8,
                                                                          )
                                                                        : colorScheme
                                                                              .onSurfaceVariant,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12.0),
                                              _isQueueLocked
                                                  ? _ItemDragInterceptor(
                                                      child: IconButton(
                                                        key: const ValueKey(
                                                          'locked_more',
                                                        ),
                                                        icon: Icon(
                                                          FlutterRemix
                                                              .more_2_fill,
                                                          color: isNowPlaying
                                                              ? colorScheme
                                                                    .onPrimaryContainer
                                                              : colorScheme
                                                                    .onSurfaceVariant,
                                                          size: 20,
                                                        ),
                                                        onPressed: () =>
                                                            M3ETrackTile.showTrackMenu(
                                                              context,
                                                              track,
                                                              showGoToOptions:
                                                                  false,
                                                            ),
                                                      ),
                                                    )
                                                  : SizedBox(
                                                      key: const ValueKey(
                                                        'unlocked_handle',
                                                      ),
                                                      width: 48,
                                                      height: 48,
                                                      child: Center(
                                                        child: Icon(
                                                          FlutterRemix
                                                              .menu_line,
                                                          color: colorScheme
                                                              .onSurfaceVariant,
                                                          size: 20,
                                                        ),
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
                                    expandedShadowElevation: 0,
                                    collapsedShadowElevation: 0,
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
                                        duration: NixDurations.short,
                                        curve: NixCurves.bouncing,
                                        child: _showScrollButton
                                            ? Padding(
                                                padding: const EdgeInsets.only(
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
                                                  tooltip: 'Scroll to playing',
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                      IconButton(
                                        onPressed: () => widget.onClose?.call(),
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
    );
  }
}

/// Absorbs long-press drag attempts on item bodies so that reorder drag is
/// exclusively triggered from the trailing handle in [M3EReorderableSegmentedList].
class _ItemDragInterceptor extends StatelessWidget {
  final Widget child;
  const _ItemDragInterceptor({required this.child});

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        DelayedMultiDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              DelayedMultiDragGestureRecognizer
            >(
              () => DelayedMultiDragGestureRecognizer(
                delay: const Duration(milliseconds: 100),
              ),
              (DelayedMultiDragGestureRecognizer instance) {
                instance.onStart = (Offset position) => null;
              },
            ),
      },
      child: child,
    );
  }
}
