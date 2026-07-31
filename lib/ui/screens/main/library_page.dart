import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/screens/main/controllers/library_controller.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final LibraryPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LibraryPageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          appBar: AppBar(
            title: const Text('Library'),
            centerTitle: true,
            scrolledUnderElevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(FlutterRemix.settings_3_line),
                onPressed: () => _controller.openSettings(context),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Consumer<MusicProvider>(
              builder: (context, music, child) {
                return NixRefreshableList(
                  onRefresh: () => _controller.refreshLibrary(context),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 20.0),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      const NixSectionHeader(title: 'Personal', topPadding: 0),

                      // Dynamic stats
                      CardListTile(
                        title: 'Listening Stats',
                        icon: FlutterRemix.bar_chart_fill,
                        subtitle: 'Overview, top tracks, artists & history',
                        isFirst: true,
                        onTap: () => _controller.openListeningStats(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'Top Listened',
                        icon: FlutterRemix.fire_fill,
                        subtitle: '${music.topPlayed.tracks.length} tracks',
                        onTap: () => _controller.openTopListened(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'Recently Listened',
                        icon: FlutterRemix.time_line,
                        subtitle: '${music.recentlyPlayed.tracks.length} tracks',
                        onTap: () => _controller.openRecentlyListened(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'Favorites',
                        icon: FlutterRemix.heart_3_fill,
                        subtitle: '${music.favorites.tracks.length} tracks',
                        isLast: true,
                        onTap: () => _controller.openFavorites(context),
                      ),
                      const SizedBox(height: 24),
                      const NixSectionHeader(title: 'Library', topPadding: 0),

                      // Media categories
                      CardListTile(
                        title: 'Artists',
                        icon: FlutterRemix.user_4_line,
                        subtitle: '${music.artists.length} artists',
                        isFirst: true,
                        onTap: () => _controller.openArtists(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'Albums',
                        icon: FlutterRemix.disc_line,
                        subtitle: '${music.albums.length} albums',
                        onTap: () => _controller.openAlbums(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'Playlists',
                        icon: FlutterRemix.play_list_line,
                        subtitle: '${music.playlists.length} playlists',
                        onTap: () => _controller.openPlaylists(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'All Tracks',
                        icon: FlutterRemix.music_2_line,
                        subtitle: '${music.tracks.length} tracks',
                        isLast: true,
                        onTap: () => _controller.openAllTracks(context),
                      ),
                      const NixBottomSpacer(),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
