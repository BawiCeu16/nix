// File: lib/ui/pages/favorite_songs_screen.dart
import 'dart:io';

import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/%20utils/translator.dart';
import 'package:nix/ui/widgets/song_details_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../providers/music_provider.dart';

class FavoriteSongsScreen extends StatelessWidget {
  const FavoriteSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final favoriteSongs = provider.songs
        .where((song) => provider.favoriteSongIds.contains(song.id))
        .toList();

    if (favoriteSongs.isEmpty) {
      return Center(child: Text(t(context, 'no_favorites_songs_yet')));
    }

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        centerTitle: true,
        title: Text(t(context, 'favorite_songs')),
        actions: [
          // Export favorites to Android system playlist (MediaStore)
          IconButton(
            tooltip: Platform.isAndroid
                ? 'Export favorites to system playlist'
                : 'Export (Android only)',
            icon: const Icon(Icons.upload_outlined),
            onPressed: Platform.isAndroid
                ? () async {
                    try {
                      await provider.exportFavoritesToSystem();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export complete')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export failed: $e')),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: LiveList.options(
          physics: const BouncingScrollPhysics(),
          options: const LiveOptions(
            delay: Duration(milliseconds: 50),
            showItemInterval: Duration(milliseconds: 80),
            showItemDuration: Duration(milliseconds: 350),
          ),
          itemCount: favoriteSongs.length,
          itemBuilder: (context, index, animation) {
            final song = favoriteSongs[index];
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: ListTile(
                  leading: QueryArtworkWidget(
                    keepOldArtwork: true,
                    artworkBorder: BorderRadius.circular(5),
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: SizedBox(
                      height: 55,
                      width: 55,
                      child: Card(
                        elevation: 0,
                        child: Icon(FlutterRemix.music_fill),
                      ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(song.artist ?? "${t(context, 'unknown')}"),
                  onTap: () => provider.playSong(song),
                  onLongPress: () => showDialog(
                    context: context,
                    builder: (context) => SongDetailsDialog(song: song),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => provider.toggleFavorite(song.id),
                      ),
                      if (provider.currentSong?.id == song.id)
                        IconButton(
                          icon: Icon(
                            provider.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: () {
                            provider.isPlaying
                                ? provider.pause()
                                : provider.resume();
                          },
                        ),
                    ],
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
