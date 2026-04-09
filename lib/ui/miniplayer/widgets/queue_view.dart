import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/list_item/queue_tile.dart';

class QueueView extends StatefulWidget {
  final double queueProgressValue;
  final double maxOffset;
  final double topInset;
  final ScrollController? controller;

  const QueueView({
    super.key,
    required this.queueProgressValue,
    required this.maxOffset,
    required this.topInset,
    this.controller,
  });

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  @override
  void didUpdateWidget(covariant QueueView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.queueProgressValue == 1.0 &&
        oldWidget.queueProgressValue < 1.0) {
      _scrollToCurrentTrack();
    }
  }

  void _scrollToCurrentTrack() {
    if (widget.queueProgressValue < 1.0) return;

    final currentMusic = context.read<CurrentMusicProvider>();
    final playing = currentMusic.currentTrack;
    if (playing == null) return;

    final tracks = currentMusic.currentPlaylist?.tracks ?? [];
    final currentIndex = tracks.indexWhere((s) => s.id == playing.id);

    if (currentIndex >= 0 && widget.controller?.hasClients == true) {
      widget.controller?.animateTo(
        currentIndex * 72.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _reorderCallback(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final currentMusic = context.read<CurrentMusicProvider>();

    currentMusic.reorderQueue(oldIndex, newIndex);
    if (context.read<SettingsProvider>().enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMusic = context.watch<CurrentMusicProvider>();
    final playlist = currentMusic.currentPlaylist;
    final tracks = playlist?.tracks ?? [];

    //show the whole queue.
    final queueTracks = tracks;

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
                    child: queueTracks.isEmpty
                        ? const Center(child: Text("Nothing in the queue."))
                        : CustomScrollView(
                            controller: widget.queueProgressValue == 1.0
                                ? widget.controller
                                : null,
                            physics: widget.queueProgressValue == 1.0
                                ? const AlwaysScrollableScrollPhysics()
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
                                  child: Text(
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
                                ),
                              ),
                              SliverReorderableList(
                                itemCount: queueTracks.length,
                                onReorder: _reorderCallback,
                                proxyDecorator: (child, index, animation) {
                                  return AnimatedBuilder(
                                    animation: animation,
                                    builder: (context, child) {
                                      return Material(
                                        elevation: 0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: .3),
                                        child: child,
                                      );
                                    },
                                    child: child,
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final track = queueTracks[index];
                                  return QueueTile(
                                    key: ValueKey('queue_${track.id}_$index'),
                                    title: track.title,
                                    subtitle: track.artist,
                                    trackId: track.id,
                                    itemIndex: index,
                                    isPlaying:
                                        currentMusic.currentTrack?.id == track.id,
                                    onTap: () {
                                      currentMusic.playTrack(
                                        track,
                                        playlist: playlist,
                                      );
                                    },
                                    onRemove: () {
                                      final realIndex = tracks.indexOf(track);
                                      if (realIndex >= 0) {
                                        currentMusic.removeFromQueue(realIndex);
                                      }
                                    },
                                    trailing: ReorderableDragStartListener(
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
                                  );
                                },
                              ),
                              const SliverPadding(
                                padding: EdgeInsets.only(bottom: 120),
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
