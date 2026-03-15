import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:nix/models/music/song.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';

class TrackTile extends StatefulWidget {
  final Song track;
  final List<Song>? playlistContext;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onPressed;

  const TrackTile({
    super.key,
    required this.track,
    this.playlistContext,
    this.isFirst = false,
    this.isLast = false,
    this.onPressed,
  });

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed != pressed && mounted) {
      setState(() => _isPressed = pressed);
    }
  }

  String get _formattedDuration {
    final min = (widget.track.duration / 60000).floor();
    final sec = ((widget.track.duration / 1000) % 60).floor().toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final defaultRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.isFirst ? 12 : 5),
      topRight: Radius.circular(widget.isFirst ? 12 : 5),
      bottomLeft: Radius.circular(widget.isLast ? 12 : 5),
      bottomRight: Radius.circular(widget.isLast ? 12 : 5),
    );

    final targetRadius = _isPressed
        ? BorderRadius.circular(100.0)
        : defaultRadius;
    final targetScale = _isPressed ? 0.98 : 1.0;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.isLast ? 0.0 : 3.0),
      child: Dismissible(
        key: ValueKey(widget.track.id),
        confirmDismiss: (direction) async {
          context.read<CurrentMusicProvider>().queueNext(widget.track);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${widget.track.title}" will play next'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return false;
        },
        direction: DismissDirection.startToEnd,
        background: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FlutterRemix.skip_forward_fill,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Play Next',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        movementDuration: const Duration(milliseconds: 50),
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.45,
          DismissDirection.endToStart: 0.45,
        },
        resizeDuration: const Duration(milliseconds: 50),
        child: Selector<CurrentMusicProvider, Song?>(
          selector: (_, p) => p.playing,
          builder: (context, currentlyPlaying, child) {
            final isNowPlaying = currentlyPlaying != null && currentlyPlaying.id == widget.track.id;

            return GestureDetector(
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              onTap: widget.onPressed ?? () {
                FocusScope.of(context).requestFocus(FocusNode());
                final currentMusic = context.read<CurrentMusicProvider>();
                Playlist? pl;
                if (widget.playlistContext != null) {
                  pl = Playlist(
                    id: 'queue_${DateTime.now().millisecondsSinceEpoch}',
                    name: 'Queue',
                    songs: widget.playlistContext!,
                    createdAt: DateTime.now(),
                  );
                }
                currentMusic.playSong(widget.track, playlist: pl);
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                final music = context.read<MusicProvider>();
                final isFav = music.isFavorite(widget.track);
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: Icon(isFav ? FlutterRemix.heart_3_fill : FlutterRemix.heart_3_line),
                          title: Text(isFav ? "Remove from Favorites" : "Add to Favorites"),
                          onTap: () {
                            music.toggleFavorite(widget.track);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          leading: const Icon(FlutterRemix.skip_forward_fill),
                          title: const Text("Play Next"),
                          onTap: () {
                            context.read<CurrentMusicProvider>().queueNext(widget.track);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          leading: const Icon(FlutterRemix.play_list_add_line),
                          title: const Text("Add to Queue"),
                          onTap: () {
                            context.read<CurrentMusicProvider>().appendToQueue(widget.track);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: AnimatedScale(
                scale: targetScale,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutQuad,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutQuad,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: targetRadius,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: _ArtworkLeading(songUri: widget.track.uri, isPlaying: isNowPlaying),
                        title: Text(
                          widget.track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: isNowPlaying
                              ? TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                        subtitle: Text(
                          '${widget.track.artist} · $_formattedDuration',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(FlutterRemix.more_2_fill, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                          onPressed: () {
                            final music = context.read<MusicProvider>();
                            final isFav = music.isFavorite(widget.track);
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading: Icon(isFav ? FlutterRemix.heart_3_fill : FlutterRemix.heart_3_line),
                                      title: Text(isFav ? "Remove from Favorites" : "Add to Favorites"),
                                      onTap: () { music.toggleFavorite(widget.track); Navigator.pop(ctx); },
                                    ),
                                    ListTile(
                                      leading: const Icon(FlutterRemix.skip_forward_fill),
                                      title: const Text("Play Next"),
                                      onTap: () { context.read<CurrentMusicProvider>().queueNext(widget.track); Navigator.pop(ctx); },
                                    ),
                                    ListTile(
                                      leading: const Icon(FlutterRemix.play_list_add_line),
                                      title: const Text("Add to Queue"),
                                      onTap: () { context.read<CurrentMusicProvider>().appendToQueue(widget.track); Navigator.pop(ctx); },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Shows artwork from Hive cached_images box, or a music icon placeholder
class _ArtworkLeading extends StatelessWidget {
  final String songUri;
  final bool isPlaying;

  const _ArtworkLeading({required this.songUri, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    Uint8List? artworkBytes;

    try {
      if (Hive.isBoxOpen('cached_images')) {
        final box = Hive.box('cached_images');
        final data = box.get(songUri);
        if (data != null && data is Uint8List) {
          artworkBytes = data;
        }
      }
    } catch (_) {}

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: artworkBytes != null
            ? Image.memory(artworkBytes, fit: BoxFit.cover)
            : Container(
                color: isPlaying
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  isPlaying ? Icons.equalizer : Icons.music_note,
                  color: isPlaying
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
