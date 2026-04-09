import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/buttons/expressive_button.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/models/music/artist.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';
import 'package:nix/ui/widgets/common/nix_empty_state.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Artists'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<_ArtistSort>(
            icon: const Icon(FlutterRemix.sort_desc),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _ArtistSort.defaultOrder,
                child: Text('Default'),
              ),
              PopupMenuItem(value: _ArtistSort.aToZ, child: Text('A → Z')),
              PopupMenuItem(value: _ArtistSort.zToA, child: Text('Z → A')),
            ],
          ),
        ],
      ),
      body: Consumer2<MusicProvider, CurrentMusicProvider>(
        builder: (context, music, currentMusic, child) {
          List<Artist> artists = List.from(music.artists);
          if (_sort == _ArtistSort.aToZ) {
            artists.sort((a, b) => a.name.compareTo(b.name));
          } else if (_sort == _ArtistSort.zToA) {
            artists.sort((a, b) => b.name.compareTo(a.name));
          }

          return NixRefreshableList(
            isEmpty: artists.isEmpty,
            onRefresh: () async => await music.scanDevice(),
            emptyState: const NixEmptyState(
              icon: FlutterRemix.user_4_line,
              title: "No artists found",
            ),
            child: GridView.builder(
              padding: EdgeInsets.only(
                bottom: NixBottomSpacer.calculateHeight(context),
                left: 16,
                right: 16,
                top: 8,
              ),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                final artistTracks = music.getTracksByArtist(artist.name);
                final firstTrackId = artistTracks.isNotEmpty
                    ? artistTracks.first.id
                    : null;

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ArtistTracksPage(artistName: artist.name),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NixArtwork(
                        id: firstTrackId ?? 0,
                        type: ArtworkType.AUDIO,
                        width: 130,
                        height: 130,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        artist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${artist.numberOfTracks} Tracks",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Artist Tracks Page ──
class ArtistTracksPage extends StatelessWidget {
  final String artistName;

  const ArtistTracksPage({super.key, required this.artistName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Artist'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
      ),
      body: Consumer<MusicProvider>(
        builder: (context, music, child) {
          final tracks = music.getTracksByArtist(artistName);
          final albums = music.getAlbumsByArtist(artistName);
          final firstTrackId = tracks.isNotEmpty ? tracks.first.id : null;

          return NixRefreshableList(
            isEmpty: tracks.isEmpty,
            onRefresh: () async => await music.scanDevice(),
            emptyState: const NixEmptyState(
              icon: FlutterRemix.user_4_line,
              title: "No tracks found for this artist",
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: tracks.length + 2, // Header + Tracks + Bottom Padding
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Header section with artwork and info
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        NixArtwork(
                          id: firstTrackId ?? 0,
                          type: ArtworkType.AUDIO,
                          width: 300,
                          height: 300,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          artistName,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${tracks.length} Tracks • ${albums.length} Albums",
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ExpressiveToneButton(
                                onPressed: () {
                                  final audio = context
                                      .read<CurrentMusicProvider>();
                                  final shuffled = List<Track>.from(tracks)
                                    ..shuffle();
                                  if (!audio.isShuffleEnabled) {
                                    audio.toggleShuffle();
                                  }
                                  audio.playTrack(shuffled.first);
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(FlutterRemix.shuffle_fill, size: 20),
                                    SizedBox(width: 8),
                                    Text('Shuffle'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ExpressiveButton(
                                onPressed: () {
                                  context
                                      .read<CurrentMusicProvider>()
                                      .playTrack(tracks.first);
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(FlutterRemix.play_fill, size: 20),
                                    SizedBox(width: 8),
                                    Text("Play All"),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                if (index == tracks.length + 1) {
                  return const NixBottomSpacer();
                }

                final track = tracks[index - 1];
                return TrackTile(
                  track: track,
                  playlistContext: tracks,
                  isFirst: index == 1,
                  isLast: index == tracks.length,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
