import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/core/nix_icons.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';

class NixPlaylistCover extends StatelessWidget {
  final Playlist playlist;
  final double size;
  final double radius;

  const NixPlaylistCover({
    super.key,
    required this.playlist,
    this.size = 48,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 1. Priority: Custom Icon & Color
    if (playlist.iconCodePoint != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: playlist.colorValue != null
              ? Color(playlist.colorValue!).withValues(alpha: 0.2)
              : colorScheme.secondaryContainer,
        ),
        child: Icon(
          NixIcons.getPlaylistIcon(playlist.iconCodePoint),
          color: playlist.colorValue != null
              ? Color(playlist.colorValue!)
              : colorScheme.onSecondaryContainer,
          size: size * 0.5,
        ),
      );
    }

    // 2. Priority: Artwork Grid (2, 3, or 4+ tracks)
    if (playlist.tracks.length >= 2) {
      // Find unique albums for a diverse grid
      final uniqueAlbumTracks = <Track>[];
      final seenAlbums = <String>{};

      for (final t in playlist.tracks) {
        if (!seenAlbums.contains(t.album)) {
          uniqueAlbumTracks.add(t);
          seenAlbums.add(t.album);
        }
        if (uniqueAlbumTracks.length == 4) break;
      }

      final trackCount = playlist.tracks.length;

      // Layout for 2 Tracks: 50/50 Vertical Split (Side-by-Side)
      if (trackCount == 2) {
        final displayTracks = uniqueAlbumTracks.length >= 2
            ? uniqueAlbumTracks.take(2).toList()
            : playlist.tracks.take(2).toList();

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: colorScheme.surfaceContainerHigh,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                child: NixArtwork(
                  id: displayTracks[0].id,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              const SizedBox(width: 1.5),
              Expanded(
                child: NixArtwork(
                  id: displayTracks[1].id,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ],
          ),
        );
      }

      // Layout for 3 Tracks: 1 Large Left, 2 Small Stacked Right
      if (trackCount == 3) {
        final displayTracks = uniqueAlbumTracks.length >= 3
            ? uniqueAlbumTracks.take(3).toList()
            : playlist.tracks.take(3).toList();

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: colorScheme.surfaceContainerHigh,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: NixArtwork(
                  id: displayTracks[0].id,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              const SizedBox(width: 1.5),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: NixArtwork(
                        id: displayTracks[1].id,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Expanded(
                      child: NixArtwork(
                        id: displayTracks[2].id,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // Layout for 4+ Tracks (Existing Grid)
      final gridTracks = uniqueAlbumTracks.length == 4
          ? uniqueAlbumTracks
          : playlist.tracks.take(4).toList();

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: colorScheme.surfaceContainerHigh,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: NixArtwork(
                      id: gridTracks[0].id,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  const SizedBox(width: 1.5),
                  Expanded(
                    child: NixArtwork(
                      id: gridTracks[1].id,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1.5),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: NixArtwork(
                      id: gridTracks[2].id,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  const SizedBox(width: 1.5),
                  Expanded(
                    child: NixArtwork(
                      id: gridTracks[3].id,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Priority: Single Artwork (1 track)
    if (playlist.tracks.isNotEmpty) {
      return NixArtwork(
        id: playlist.tracks[0].id,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(radius),
      );
    }

    // 4. Fallback: Default Icon
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: colorScheme.secondaryContainer,
      ),
      child: Icon(
        FlutterRemix.play_list_line,
        color: colorScheme.onSecondaryContainer,
        size: size * 0.5,
      ),
    );
  }
}
