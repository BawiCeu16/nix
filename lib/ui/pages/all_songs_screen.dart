// lib/ui/pages/all_songs_screen.dart
import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:mini_music_visualizer/mini_music_visualizer.dart';
import 'package:nix/ui/widgets/recent_and_most.dart';
import 'package:nix/ui/widgets/search_bar_widget.dart';
import 'package:nix/ui/widgets/song_details_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../providers/music_provider.dart';

class AllSongsScreen extends StatelessWidget {
  const AllSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MusicProvider>();
    final isMiniPlayerOpen = context.select<MusicProvider, bool>(
      (p) => p.currentSong != null,
    );

    return RefreshIndicator(
      onRefresh: () async => await provider.refreshSongs(),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // const SliverToBoxAdapter(child: SearchBarWidget()),
          SliverFloatingHeader(child: SearchBarWidget()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // Recently played strip stays in AllSongs
          const SliverToBoxAdapter(child: RecentlyPlayedStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Songs list (animated)
          Selector<MusicProvider, List<SongModel>>(
            selector: (_, provider) => provider.filteredSongs,
            builder: (context, songs, _) {
              if (songs.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text("No songs found.")),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.only(
                  bottom: isMiniPlayerOpen
                      ? 90
                      : 16, // reserve space for mini player
                  top: 0,
                ),
                sliver: SliverToBoxAdapter(
                  child: LiveList.options(
                    key: const PageStorageKey('songs_list'),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    options: const LiveOptions(
                      delay: Duration(milliseconds: 50),
                      showItemInterval: Duration(milliseconds: 80),
                      showItemDuration: Duration(milliseconds: 350),
                    ),
                    itemCount: songs.length,
                    itemBuilder: (context, index, animation) {
                      final song = songs[index];
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: _SongTile(song: song),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // bottom spacer
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

/// Helper to format duration (assumes [ms] is milliseconds).
/// If your SongModel.duration is in seconds, change the conversion accordingly.
String formatDuration(int? ms) {
  if (ms == null || ms <= 0) return "--:--";
  final totalSeconds = (ms / 1000).round();
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  final twoDigits = (int n) => n.toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
  } else {
    return '${minutes}:${twoDigits(seconds)}';
  }
}

class _SongTile extends StatelessWidget {
  final SongModel song;
  const _SongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    return Selector<MusicProvider, _SongTileState>(
      selector: (_, provider) => _SongTileState(
        isCurrentSong: provider.currentSong?.id == song.id,
        isPlaying: provider.isPlaying,
        isFavorite: provider.isFavorite(song.id),
      ),
      builder: (context, state, _) {
        final provider = context.read<MusicProvider>();

        return ListTile(
          key: ValueKey(song.id),
          leading: Hero(
            tag: "artwork-${song.id}",
            child: QueryArtworkWidget(
              keepOldArtwork: true,
              artworkBorder: BorderRadius.circular(5),
              id: song.id,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: SizedBox(
                height: 55,
                width: 55,
                child: Card(elevation: 0, child: Icon(FlutterRemix.music_fill)),
              ),
            ),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            "${song.artist ?? "Unknown"} • ${formatDuration(song.duration)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            // record click (updates recent & counts) then play
            provider.recordClickAndPlay(song);
          },
          onLongPress: () => showDialog(
            context: context,
            builder: (_) => SongDetailsDialog(song: song),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  state.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: state.isFavorite ? Colors.red : null,
                ),
                onPressed: () => provider.toggleFavorite(song.id),
              ),
              if (state.isCurrentSong)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: MiniMusicVisualizer(
                    width: 4,
                    height: 15,
                    animate: state.isPlaying,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SongTileState {
  final bool isCurrentSong;
  final bool isPlaying;
  final bool isFavorite;

  _SongTileState({
    required this.isCurrentSong,
    required this.isPlaying,
    required this.isFavorite,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SongTileState &&
          runtimeType == other.runtimeType &&
          isCurrentSong == other.isCurrentSong &&
          isPlaying == other.isPlaying &&
          isFavorite == other.isFavorite;

  @override
  int get hashCode =>
      isCurrentSong.hashCode ^ isPlaying.hashCode ^ isFavorite.hashCode;
}
