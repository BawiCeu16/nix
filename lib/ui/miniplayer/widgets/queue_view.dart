import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
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
  void _reorderCallback(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final currentMusic = context.read<CurrentMusicProvider>();
    final playlist = currentMusic.currentPlaylist;
    final songs = playlist?.songs ?? [];
    final currentSong = currentMusic.currentSong;

    final currentIndex = currentSong != null
        ? songs.indexWhere((s) => s.id == currentSong.id)
        : -1;

    final realOld = (currentIndex >= 0 ? currentIndex + 1 : 0) + oldIndex;
    final realNew = (currentIndex >= 0 ? currentIndex + 1 : 0) + newIndex;

    currentMusic.reorderQueue(realOld, realNew);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final currentMusic = context.watch<CurrentMusicProvider>();
    final playlist = currentMusic.currentPlaylist;
    final songs = playlist?.songs ?? [];
    final currentSong = currentMusic.currentSong;

    // Find current index to show "Up Next"
    final currentIndex = currentSong != null
        ? songs.indexWhere((s) => s.id == currentSong.id)
        : -1;
    final upNextSongs = currentIndex >= 0 && currentIndex < songs.length - 1
        ? songs.sublist(currentIndex + 1)
        : songs;

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
                    child: upNextSongs.isEmpty
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
                                    "Up Next",
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
                                itemCount: upNextSongs.length,
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
                                  final song = upNextSongs[index];
                                  return QueueTile(
                                    key: ValueKey('queue_${song.id}_$index'),
                                    title: song.title,
                                    subtitle: song.artist,
                                    songUri: song.uri,
                                    itemIndex: index,
                                    onTap: () {
                                      currentMusic.playSong(
                                        song,
                                        playlist: playlist,
                                      );
                                    },
                                    onRemove: () {
                                      final realIndex = songs.indexOf(song);
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
                              // const SliverPadding(
                              //   padding: EdgeInsets.only(bottom: 100),
                              // ),
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
