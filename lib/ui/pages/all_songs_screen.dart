import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:mini_music_visualizer/mini_music_visualizer.dart';
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

    return RefreshIndicator(
      onRefresh: () async => await provider.refreshSongs(),
      child: Column(
        children: [
          const SearchBarWidget(),
          Expanded(
            child: Selector<MusicProvider, List<SongModel>>(
              selector: (_, p) => p.filteredSongs,
              builder: (context, songs, _) {
                if (songs.isEmpty) {
                  return const Center(child: Text("No songs found."));
                }
                return LiveList.options(
                  key: const PageStorageKey('songs_list'),
                  physics: const BouncingScrollPhysics(),
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
                );
              },
            ),
          ),
        ],
      ),
    );
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
          subtitle: Text(song.artist ?? "Unknown"),
          onTap: () => provider.playSong(song),
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
                MiniMusicVisualizer(
                  width: 4,
                  height: 15,
                  animate: state.isPlaying,
                  color: Theme.of(context).colorScheme.primary,
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
