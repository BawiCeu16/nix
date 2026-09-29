import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/dialogs/playlist_dialogs.dart';
import 'package:nix/ui/widgets/dialogs/track_info_dialog.dart';
import 'package:nix/core/format.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/screens/music/artists_page.dart';
import 'package:nix/ui/screens/music/albums_page.dart';
import 'package:nix/services/snackbar_service.dart';

/// A pure Material 3 Expressive segmented track tile built with
/// [M3ESegmentedItem] and [M3EListItem].
class M3ETrackTile extends StatelessWidget {
  final Track track;
  final List<Track>? playlistContext;
  final int? index;
  final int? totalCount;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onPressed;
  final Widget? trailing;

  const M3ETrackTile({
    super.key,
    required this.track,
    this.playlistContext,
    this.index,
    this.totalCount,
    this.isFirst = false,
    this.isLast = false,
    this.onPressed,
    this.trailing,
  });

  M3ESegmentedItemPosition get _position {
    if (index != null && totalCount != null) {
      return calculateSegmentedItemPosition(index!, totalCount!);
    }
    if (isFirst && isLast) return M3ESegmentedItemPosition.single;
    if (isFirst) return M3ESegmentedItemPosition.first;
    if (isLast) return M3ESegmentedItemPosition.last;
    return M3ESegmentedItemPosition.middle;
  }

  bool get _isLastItem {
    if (index != null && totalCount != null) {
      return index == totalCount! - 1;
    }
    return isLast;
  }

  String get _formattedDuration {
    return Duration(milliseconds: track.duration).shortFormat();
  }

  static void handleQueueAction(
    BuildContext context,
    Track track,
    QueueResult result,
    String actionType,
  ) {
    if (!context.mounted) return;
    final currentMusic = context.read<CurrentMusicProvider>();
    String message = '';

    switch (result) {
      case QueueResult.success:
        message = actionType == 'next'
            ? '"${track.title}" will play next'
            : 'Added "${track.title}" to queue';
        context.showSuccessSnackBar(message);
        break;
      case QueueResult.duplicate:
        message =
            '"${track.title}" is already in queue. Want to move it after this track?';
        context.showInfoSnackBar(
          message,
          trailing: TextButton(
            onPressed: () {
              currentMusic.moveTrackToPlayNext(track);
              context.showSuccessSnackBar(
                'Moved "${track.title}" to Play Next',
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

  static void showTrackMenu(
    BuildContext context,
    Track track, {
    bool showGoToOptions = true,
  }) {
    final music = context.read<MusicProvider>();
    final currentMusic = context.read<CurrentMusicProvider>();
    final isFav = music.isFavorite(track);
    final bool isPlaying = currentMusic.showMiniPlayer;

    NixDialog.show(
      context: context,
      title: track.title,
      subtitle: track.artist,
      trackId: track.id,

      titleAlignment: CrossAxisAlignment.start,
      children: [
        CardListTile(
          title: isFav ? "Remove from Favorites" : "Add to Favorites",
          icon: isFav ? FlutterRemix.heart_3_fill : FlutterRemix.heart_3_line,
          isFirst: true,
          onTap: () {
            music.toggleFavorite(track);
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: isPlaying ? "Play Next" : "Play Now",
          icon: isPlaying
              ? FlutterRemix.skip_forward_fill
              : FlutterRemix.play_fill,
          onTap: () {
            if (isPlaying) {
              final result = currentMusic.queueNext(track);
              Navigator.of(context, rootNavigator: true).pop();
              handleQueueAction(context, track, result, 'next');
            } else {
              currentMusic.playTrack(track);
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Add to Queue",
          icon: FlutterRemix.play_list_add_line,
          onTap: () {
            final result = currentMusic.appendToQueue(track);
            Navigator.of(context, rootNavigator: true).pop();
            handleQueueAction(context, track, result, 'append');
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Add to Playlist",
          icon: FlutterRemix.add_box_line,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            PlaylistDialogs.showPlaylistPicker(context, track);
          },
        ),
        if (showGoToOptions) ...[
          const SizedBox(height: 2.5),
          CardListTile(
            title: "Go to Artist",
            icon: FlutterRemix.user_4_line,
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArtistTracksPage(artistName: track.artist),
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
                    albumTitle: track.album,
                    albumArtist: track.artist,
                  ),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 2.5),
        CardListTile(
          title: "Track Info",
          icon: FlutterRemix.information_line,
          isLast: true,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            TrackInfoDialog.show(
              context,
              title: track.title,
              artist: track.artist,
              album: track.album,
              duration: Duration(milliseconds: track.duration).shortFormat(),
              size: track.size.formatBytes(),
              filePath: track.uri,
              trackId: track.id,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final showSwipe = settings.trackSwipeAction != TrackSwipeAction.none;

    final Widget tileContent = Selector<CurrentMusicProvider, Track?>(
      selector: (_, p) => p.currentTrack,
      builder: (context, currentlyPlaying, child) {
        final isNowPlaying =
            currentlyPlaying != null && currentlyPlaying.id == track.id;
        final colorScheme = Theme.of(context).colorScheme;

        return M3ESegmentedItem(
          index: index ?? track.id,
          position: _position,
          outerRadius: 16.0,
          innerRadius: 5.0,
          pressedRadius: 100.0,
          pressedScale: 0.98,
          hoveredRadius: 16.0,
          selectedRadius: 100.0,
          gap: 2.5,
          isLast: _isLastItem,

          isSelected: isNowPlaying,
          selectedColor: colorScheme.primaryContainer,
          color: colorScheme.surface,
          padding: EdgeInsets.zero,
          onTap: (_) {
            if (onPressed != null) {
              onPressed!();
            } else {
              FocusScope.of(context).requestFocus(FocusNode());
              final currentMusic = context.read<CurrentMusicProvider>();
              Playlist? pl;
              if (playlistContext != null) {
                pl = Playlist(
                  id: 'queue_${DateTime.now().millisecondsSinceEpoch}',
                  name: 'Queue',
                  tracks: playlistContext!,
                  createdAt: DateTime.now(),
                );
              }
              currentMusic.playTrack(track, playlist: pl);
            }
          },
          onLongPress: (_) {
            if (context.read<SettingsProvider>().enableHaptics) {
              HapticFeedback.mediumImpact();
            }
            TrackInfoDialog.show(
              context,
              title: track.title,
              artist: track.artist,
              album: track.album,
              duration: _formattedDuration,
              size: track.size.formatBytes(),
              filePath: track.uri,
              trackId: track.id,
            );
          },
          child: M3ETrackContent(
            track: track,
            isNowPlaying: isNowPlaying,
            trailing: trailing,
          ),
        );
      },
    );

    if (!showSwipe) {
      return tileContent;
    }

    return Dismissible(
      key: ValueKey('m3e_swipe_${track.id}'),
      confirmDismiss: (direction) async {
        final currentMusic = context.read<CurrentMusicProvider>();
        final bool isPlaying = currentMusic.showMiniPlayer;

        if (isPlaying) {
          final result = currentMusic.queueNext(track);
          handleQueueAction(context, track, result, 'next');
        } else {
          currentMusic.playTrack(track);
        }
        return false;
      },
      direction: DismissDirection.startToEnd,
      background: Consumer<CurrentMusicProvider>(
        builder: (context, music, _) {
          final bool isPlaying = music.showMiniPlayer;
          final colorScheme = Theme.of(context).colorScheme;

          return Padding(
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
          );
        },
      ),
      movementDuration: const Duration(milliseconds: 50),
      dismissThresholds: const {DismissDirection.startToEnd: 0.45},
      resizeDuration: const Duration(milliseconds: 50),
      child: tileContent,
    );
  }
}

/// Artwork thumbnail for [M3ETrackTile]
class M3EArtworkLeading extends StatelessWidget {
  final int trackId;
  final bool isPlaying;

  const M3EArtworkLeading({
    super.key,
    required this.trackId,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final targetRadius = isPlaying
        ? BorderRadius.circular(100.0)
        : BorderRadius.circular(12.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
      width: 48,
      height: 48,
      decoration: BoxDecoration(borderRadius: targetRadius),
      clipBehavior: Clip.antiAlias,
      child: NixArtwork(
        id: trackId,
        type: ArtworkType.AUDIO,
        borderRadius: targetRadius,
        width: 48,
        height: 48,
      ),
    );
  }
}

/// Content layout for a track inside Material 3 Expressive segmented lists.
class M3ETrackContent extends StatelessWidget {
  final Track track;
  final bool isNowPlaying;
  final Widget? trailing;

  const M3ETrackContent({
    super.key,
    required this.track,
    this.isNowPlaying = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showResume = context.select<SettingsProvider, bool>(
      (s) => s.resumeFromPlayedDuration,
    );
    final durationStr = Duration(milliseconds: track.duration).shortFormat();

    return M3EListItem(
      leading: M3EArtworkLeading(trackId: track.id, isPlaying: isNowPlaying),
      headline: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      headlineStyle: TextStyle(
        fontSize: 16,
        fontWeight: isNowPlaying ? FontWeight.bold : FontWeight.w500,
        color: isNowPlaying
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
      ),
      supportingText: ValueListenableBuilder<Box<int>>(
        valueListenable: Hive.box<int>(
          HiveKeys.trackPositionsBox,
        ).listenable(keys: [track.id]),
        builder: (context, box, _) {
          final savedMs = showResume ? box.get(track.id) : null;
          final formattedDuration = savedMs != null
              ? '${Duration(milliseconds: savedMs).shortFormat()} / $durationStr'
              : durationStr;

          return Text(
            '${track.artist} · $formattedDuration',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isNowPlaying
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                  : colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
      trailing:
          trailing ??
          IconButton(
            icon: Icon(
              FlutterRemix.more_2_fill,
              color: isNowPlaying
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () => M3ETrackTile.showTrackMenu(context, track),
          ),
    );
  }
}
