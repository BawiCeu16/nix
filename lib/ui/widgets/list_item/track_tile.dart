import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/models/music/song.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';
import 'package:nix/ui/widgets/dialogs/song_info_dialog.dart';
import 'package:nix/core/format.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../screens/music_pages/artists_page.dart';
import '../../screens/music_pages/albums_page.dart';

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
    return Duration(milliseconds: widget.track.duration).shortFormat();
  }

  void _handleQueueAction(
    BuildContext context,
    QueueResult result,
    String actionType,
  ) {
    if (!context.mounted) return;
    String message = '';
    switch (result) {
      case QueueResult.success:
        message = actionType == 'next'
            ? '"${widget.track.title}" will play next'
            : 'Added "${widget.track.title}" to queue';
        break;
      case QueueResult.duplicate:
        message = '"${widget.track.title}" is already in the queue';
        break;
      case QueueResult.error:
        message = 'Failed to update queue';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTrackMenu(BuildContext context) {
    final music = context.read<MusicProvider>();
    final currentMusic = context.read<CurrentMusicProvider>();
    final isFav = music.isFavorite(widget.track);

    NixDialog.show(
      context: context,
      title: widget.track.title,
      subtitle: widget.track.artist,
      songId: widget.track.id,
      children: [
        CardListTile(
          title: isFav ? "Remove from Favorites" : "Add to Favorites",
          icon: isFav ? FlutterRemix.heart_3_fill : FlutterRemix.heart_3_line,
          isFirst: true,
          onTap: () {
            music.toggleFavorite(widget.track);
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Play Next",
          icon: FlutterRemix.skip_forward_fill,
          onTap: () {
            final result = currentMusic.queueNext(widget.track);
            Navigator.of(context, rootNavigator: true).pop();
            _handleQueueAction(context, result, 'next');
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Add to Queue",
          icon: FlutterRemix.play_list_add_line,
          onTap: () {
            final result = currentMusic.appendToQueue(widget.track);
            Navigator.of(context, rootNavigator: true).pop();
            _handleQueueAction(context, result, 'append');
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Add to Playlist",
          icon: FlutterRemix.add_box_line,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            PlaylistDialogs.showPlaylistPicker(context, widget.track);
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Go to Artist",
          icon: FlutterRemix.user_4_line,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ArtistSongsPage(artistName: widget.track.artist),
              ),
            );
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Go to Album",
          icon: FlutterRemix.disc_line,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlbumSongsPage(
                  albumTitle: widget.track.album,
                  albumArtist: widget.track.artist,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Song Info",
          icon: FlutterRemix.information_line,
          isLast: true,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            SongInfoDialog.show(
              context,
              title: widget.track.title,
              artist: widget.track.artist,
              album: widget.track.album,
              duration: _formattedDuration,
              size: widget.track.size.formatBytes(),
              filePath: widget.track.uri,
              songId: widget.track.id,
            );
          },
        ),
      ],
    );
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
      padding: EdgeInsets.only(bottom: widget.isLast ? 0.0 : 2.5),
      child: Dismissible(
        key: ValueKey(widget.track.id),
        confirmDismiss: (direction) async {
          final result = context.read<CurrentMusicProvider>().queueNext(
            widget.track,
          );
          _handleQueueAction(context, result, 'next');
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
            final isNowPlaying =
                currentlyPlaying != null &&
                currentlyPlaying.id == widget.track.id;

            return GestureDetector(
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              onTap:
                  widget.onPressed ??
                  () {
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
                if (context.read<SettingsProvider>().enableHaptics) {
                  HapticFeedback.mediumImpact();
                }
                SongInfoDialog.show(
                  context,
                  title: widget.track.title,
                  artist: widget.track.artist,
                  album: widget.track.album,
                  duration: _formattedDuration,
                  size: widget.track.size.formatBytes(),
                  filePath: widget.track.uri,
                  songId: widget.track.id,
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
                        leading: _ArtworkLeading(
                          songId: widget.track.id,
                          isPlaying: isNowPlaying,
                        ),
                        title: Text(
                          widget.track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: isNowPlaying
                              ? TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        subtitle: Text(
                          '${widget.track.artist} · $_formattedDuration',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            FlutterRemix.more_2_fill,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () => _showTrackMenu(context),
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

/// Shows artwork from MediaStore via on_audio_query
class _ArtworkLeading extends StatelessWidget {
  final int songId;
  final bool isPlaying;

  const _ArtworkLeading({required this.songId, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          keepOldArtwork: true,
          artworkFit: BoxFit.cover,
          artworkBorder: BorderRadius.circular(8),
          artworkQuality: FilterQuality.high,
          artworkWidth: 200,
          artworkHeight: 200,
          nullArtworkWidget: Container(
            color: isPlaying
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            child: Icon(
              isPlaying ? FlutterRemix.pulse_fill : FlutterRemix.music_2_line,
              color: isPlaying
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
