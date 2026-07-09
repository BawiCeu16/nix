import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';
import 'package:nix/ui/widgets/dialogs/track_info_dialog.dart';
import 'package:nix/core/format.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import '../common/nix_artwork.dart';
import '../../screens/music_pages/artists_page.dart';
import '../../screens/music_pages/albums_page.dart';
import '../../../../services/snackbar_service.dart';

class TrackTile extends StatefulWidget {
  final Track track;
  final List<Track>? playlistContext;
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
    final currentMusic = context.read<CurrentMusicProvider>();
    String message = '';

    switch (result) {
      case QueueResult.success:
        message = actionType == 'next'
            ? '"${widget.track.title}" will play next'
            : 'Added "${widget.track.title}" to queue';
        context.showSuccessSnackBar(message);
        break;
      case QueueResult.duplicate:
        message =
            '"${widget.track.title}" is already in queue. Want to move it after this track?';
        context.showInfoSnackBar(
          message,
          trailing: TextButton(
            onPressed: () {
              currentMusic.moveTrackToPlayNext(widget.track);
              context.showSuccessSnackBar(
                'Moved "${widget.track.title}" to Play Next',
              );
            },
            child: Text(
              'MOVE',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
        break;
      case QueueResult.error:
        message = 'Failed to update queue';
        context.showErrorSnackBar(message);
        break;
    }
  }

  void _showTrackMenu(BuildContext context) {
    final music = context.read<MusicProvider>();
    final currentMusic = context.read<CurrentMusicProvider>();
    final isFav = music.isFavorite(widget.track);
    final bool isPlaying = currentMusic.showMiniPlayer;

    NixDialog.show(
      context: context,
      title: widget.track.title,
      subtitle: widget.track.artist,
      trackId: widget.track.id,

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
        // Dynamic Play Now / Play Next Action
        CardListTile(
          title: isPlaying ? "Play Next" : "Play Now",
          icon: isPlaying
              ? FlutterRemix.skip_forward_fill
              : FlutterRemix.play_fill,
          onTap: () {
            if (isPlaying) {
              final result = currentMusic.queueNext(widget.track);
              Navigator.of(context, rootNavigator: true).pop();
              _handleQueueAction(context, result, 'next');
            } else {
              currentMusic.playTrack(widget.track);
              Navigator.of(context, rootNavigator: true).pop();
            }
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
                    ArtistTracksPage(artistName: widget.track.artist),
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
                builder: (_) => AlbumTracksPage(
                  albumTitle: widget.track.album,
                  albumArtist: widget.track.artist,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Track Info",
          icon: FlutterRemix.information_line,
          isLast: true,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            TrackInfoDialog.show(
              context,
              title: widget.track.title,
              artist: widget.track.artist,
              album: widget.track.album,
              duration: _formattedDuration,
              size: widget.track.size.formatBytes(),
              filePath: widget.track.uri,
              trackId: widget.track.id,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.isFirst ? 16 : 5),
      topRight: Radius.circular(widget.isFirst ? 16 : 5),
      bottomLeft: Radius.circular(widget.isLast ? 16 : 5),
      bottomRight: Radius.circular(widget.isLast ? 16 : 5),
    );

    final targetRadius = _isPressed
        ? BorderRadius.circular(100.0)
        : defaultRadius;
    final targetScale = _isPressed ? 0.98 : 1.0;

    final showSwipe = context.select<SettingsProvider, bool>(
      (s) => s.trackSwipeAction != TrackSwipeAction.none,
    );

    Widget tileContent = Selector<CurrentMusicProvider, Track?>(
      selector: (_, p) => p.currentTrack,
      builder: (context, currentlyPlaying, child) {
        final isNowPlaying =
            currentlyPlaying != null && currentlyPlaying.id == widget.track.id;

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
                    tracks: widget.playlistContext!,
                    createdAt: DateTime.now(),
                  );
                }
                currentMusic.playTrack(widget.track, playlist: pl);
              },
          onLongPress: () {
            if (context.read<SettingsProvider>().enableHaptics) {
              HapticFeedback.mediumImpact();
            }
            TrackInfoDialog.show(
              context,
              title: widget.track.title,
              artist: widget.track.artist,
              album: widget.track.album,
              duration: _formattedDuration,
              size: widget.track.size.formatBytes(),
              filePath: widget.track.uri,
              trackId: widget.track.id,
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
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: ListTile(
                    leading: _ArtworkLeading(
                      trackId: widget.track.id,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    );

    if (!showSwipe) {
      return Padding(
        padding: EdgeInsets.only(bottom: widget.isLast ? 0.0 : 2.5),
        child: tileContent,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: widget.isLast ? 0.0 : 2.5),
      child: Dismissible(
        key: ValueKey('swipe_${widget.track.id}'),
        confirmDismiss: (direction) async {
          final currentMusic = context.read<CurrentMusicProvider>();
          final bool isPlaying = currentMusic.showMiniPlayer;

          if (isPlaying) {
            final result = currentMusic.queueNext(widget.track);
            _handleQueueAction(context, result, 'next');
          } else {
            currentMusic.playTrack(widget.track);
          }
          return false;
        },
        direction: DismissDirection.startToEnd,
        background: Consumer<CurrentMusicProvider>(
          builder: (context, music, _) {
            final bool isPlaying = music.showMiniPlayer;
            final colorScheme = Theme.of(context).colorScheme;

            return Container(
              color: isPlaying
                  ? colorScheme.primaryContainer
                  : colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPlaying
                            ? FlutterRemix.skip_forward_fill
                            : FlutterRemix.play_fill,
                        color: isPlaying
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPlaying ? 'Play Next' : 'Play Now',
                        style: TextStyle(
                          color: isPlaying
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        movementDuration: const Duration(milliseconds: 50),
        dismissThresholds: const {DismissDirection.startToEnd: 0.45},
        resizeDuration: const Duration(milliseconds: 50),
        child: tileContent,
      ),
    );
  }
}

/// Shows artwork from MediaStore via on_audio_query
class _ArtworkLeading extends StatelessWidget {
  final int trackId;
  final bool isPlaying;

  const _ArtworkLeading({required this.trackId, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: NixArtwork(
        id: trackId,
        type: ArtworkType.AUDIO,
        width: 48,
        height: 48,
      ),
    );
  }
}
