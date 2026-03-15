import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/widgets/list_item/queue_tile.dart';

class QueueView extends StatelessWidget {
  final double queueProgressValue;
  final double maxOffset;
  final double topInset;

  const QueueView({
    super.key,
    required this.queueProgressValue,
    required this.maxOffset,
    required this.topInset,
  });

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
      offset: Offset(0, (1 - queueProgressValue) * maxOffset),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(top: topInset + 60),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12.0),
              topRight: Radius.circular(12.0),
            ),
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: upNextSongs.isEmpty
                  ? const Center(child: Text("Nothing in the queue."))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(
                            left: 24.0,
                            top: 24.0,
                            bottom: 12.0,
                          ),
                          child: Text(
                            "Up Next",
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ReorderableListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: upNextSongs.length,
                            proxyDecorator: (child, index, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) {
                                  final elevation = Tween<double>(
                                    begin: 0,
                                    end: 1,
                                  ).evaluate(animation);
                                  return Material(
                                    elevation: elevation,
                                    color: Colors.transparent,
                                    shadowColor: Theme.of(
                                      context,
                                    ).colorScheme.background,
                                    child: child,
                                  );
                                },
                                child: child,
                              );
                            },
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex--;
                              final realOld =
                                  (currentIndex >= 0 ? currentIndex + 1 : 0) +
                                  oldIndex;
                              final realNew =
                                  (currentIndex >= 0 ? currentIndex + 1 : 0) +
                                  newIndex;
                              currentMusic.reorderQueue(realOld, realNew);
                              HapticFeedback.lightImpact();
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
                                // Trailing drag handle — long press to start reorder
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
