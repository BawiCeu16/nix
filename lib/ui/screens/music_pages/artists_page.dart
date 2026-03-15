import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/models/music/artist.dart';

enum _ArtistSort { defaultOrder, aToZ, zToA }

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  _ArtistSort _sort = _ArtistSort.defaultOrder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Artists'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<_ArtistSort>(
            icon: const Icon(FlutterRemix.sort_desc),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _ArtistSort.defaultOrder, child: Text('Default')),
              PopupMenuItem(value: _ArtistSort.aToZ, child: Text('A → Z')),
              PopupMenuItem(value: _ArtistSort.zToA, child: Text('Z → A')),
            ],
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, music, child) {
          List<Artist> artists = List.from(music.artists);
          if (_sort == _ArtistSort.aToZ) {
            artists.sort((a, b) => a.name.compareTo(b.name));
          } else if (_sort == _ArtistSort.zToA) {
            artists.sort((a, b) => b.name.compareTo(a.name));
          }

          if (artists.isEmpty) {
            return const Center(child: Text("No artists found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(FlutterRemix.user_4_line, color: Theme.of(context).colorScheme.onSecondaryContainer),
                ),
                title: Text(artist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text("${artist.numberOfTracks} Songs • ${artist.numberOfAlbums} Albums"),
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}
