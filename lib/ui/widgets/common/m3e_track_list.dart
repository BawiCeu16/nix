import 'package:flutter/material.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:provider/provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/widgets/tiles/m3e_track_tile.dart';

/// Reusable track list component utilizing pure [M3ESegmentedList.builder] and [M3ETrackContent].
class M3ETrackList extends StatelessWidget {
  final List<Track> tracks;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final List<Track>? playlistContext;
  final void Function(Track track)? onTrackTap;
  final M3ESelectionMode selectionMode;
  final M3ESelectionTrigger selectionTrigger;
  final Set<int>? selectedIndices;
  final ValueChanged<Set<int>>? onSelectionChanged;
  final M3ESegmentedListDecoration? decoration;
  final Widget Function(Track track, int index)? trailingBuilder;

  static const defaultDecoration = M3ESegmentedListDecoration(
    outerRadius: 16.0,
    innerRadius: 5.0,
    pressedRadius: 100.0,
    pressedScale: 0.98,
    hoveredRadius: 16.0,
    selectedRadius: 100.0,
    gap: 2.5,
    padding: EdgeInsets.zero,
    margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
  );

  const M3ETrackList({
    super.key,
    required this.tracks,
    this.controller,
    this.physics,
    this.playlistContext,
    this.onTrackTap,
    this.selectionMode = M3ESelectionMode.single,
    this.selectionTrigger = M3ESelectionTrigger.tap,
    this.selectedIndices,
    this.onSelectionChanged,
    this.decoration,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final currentMusic = context.watch<CurrentMusicProvider>();
    final playingTrackId = currentMusic.currentTrack?.id;
    final colorScheme = Theme.of(context).colorScheme;

    final playingIndex = playingTrackId != null
        ? tracks.indexWhere((t) => t.id == playingTrackId)
        : -1;
    final effectiveSelectedIndices =
        selectedIndices ??
        (playingIndex != -1 ? {playingIndex} : const <int>{});

    final effectiveDecoration = (decoration ?? M3ETrackList.defaultDecoration)
        .copyWith(
          color: decoration?.color ?? colorScheme.surface,
          selectedColor:
              decoration?.selectedColor ?? colorScheme.primaryContainer,
        );

    return M3ESegmentedList.builder(
      controller: controller,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: tracks.length,
      selectionMode: selectionMode,
      selectionTrigger: selectionTrigger,
      selectedIndices: effectiveSelectedIndices,
      isSelected: (index) => tracks[index].id == playingTrackId,
      onSelectionChanged: onSelectionChanged,
      onTap: (index) {
        final track = tracks[index];
        onSelectionChanged?.call({index});
        if (onTrackTap != null) {
          onTrackTap!(track);
        } else {
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
      decoration: effectiveDecoration,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isNowPlaying = playingTrackId == track.id;
        return M3ETrackContent(
          track: track,
          isNowPlaying: isNowPlaying,
          trailing: trailingBuilder?.call(track, index),
        );
      },
    );
  }
}
