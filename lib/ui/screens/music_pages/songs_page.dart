import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:nix/models/music/song.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';

enum _SongSort { defaultOrder, aToZ, zToA, duration }

class SongsPage extends StatefulWidget {
  final String title;
  final List<Song> Function() songsSource;

  const SongsPage({super.key, required this.title, required this.songsSource});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  _SongSort _sort = _SongSort.defaultOrder;

  @override
  Widget build(BuildContext context) {
    // Dynamically fetch the current state of songs whenever it builds
    List<Song> songsList = widget.songsSource();

    // Basic sorting stub
    if (_sort == _SongSort.aToZ) {
      songsList.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sort == _SongSort.zToA) {
      songsList.sort((a, b) => b.title.compareTo(a.title));
    } else if (_sort == _SongSort.duration) {
      songsList.sort((a, b) => a.duration.compareTo(b.duration));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<_SongSort>(
            icon: const Icon(FlutterRemix.sort_desc),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _SongSort.defaultOrder,
                child: Text('Default'),
              ),
              PopupMenuItem(value: _SongSort.aToZ, child: Text('A → Z')),
              PopupMenuItem(value: _SongSort.zToA, child: Text('Z → A')),
              PopupMenuItem(value: _SongSort.duration, child: Text('Duration')),
            ],
          ),
        ],
      ),
      // floatingActionButton: songsList.isEmpty ? null : FloatingActionButton.extended(
      //   elevation: 0,
      //   icon: const Icon(FlutterRemix.shuffle_fill),
      //   label: const Text('Shuffle All'),
      //   onPressed: () {
      //     final audioProvider = context.read<CurrentMusicProvider>();
      //     final shuffled = List<Song>.from(songsList)..shuffle();
      //     if (shuffled.isNotEmpty) {
      //        if (!audioProvider.isShuffleEnabled) audioProvider.toggleShuffle();
      //        audioProvider.playSong(shuffled.first);
      //     }
      //   },
      // ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: songsList.isEmpty
            ? const NixEmptyState(
                icon: FlutterRemix.music_2_line,
                title: "No songs available",
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120, top: 8),
                itemCount: songsList.length,
                itemBuilder: (context, index) {
                  final song = songsList[index];
                  return TrackTile(
                    track: song,
                    playlistContext: songsList,
                    isFirst: index == 0,
                    isLast: index == songsList.length - 1,
                  );
                },
              ),
      ),
    );
  }
}
