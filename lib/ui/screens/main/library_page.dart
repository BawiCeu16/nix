import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
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
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<MusicProvider>(
              builder: (context, music, child) {
                return NixRefreshableList(
                  onRefresh: () => _controller.refreshLibrary(context),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8.0),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      // Primary Library Categories
                      CardListTile(
                        title: 'Playlists',
                        icon: FlutterRemix.play_list_line,
                        isFirst: true,
                        onTap: () => _controller.openPlaylists(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'Artists',
                        icon: FlutterRemix.user_4_line,
                        onTap: () => _controller.openArtists(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'Albums',
                        icon: FlutterRemix.disc_line,
                        onTap: () => _controller.openAlbums(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'Songs',
                        icon: FlutterRemix.music_2_line,
                        isLast: true,
                        onTap: () => _controller.openAllTracks(context),
                      ),
                      const SizedBox(height: 16),

                      // Personal & Activity
                      CardListTile(
                        title: 'Favorites',
                        icon: FlutterRemix.heart_3_line,
                        isFirst: true,
                        onTap: () => _controller.openFavorites(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'Recently Played',
                        icon: FlutterRemix.time_line,
                        onTap: () => _controller.openRecentlyListened(context),
                      ),
                      const SizedBox(height: 2.5),
                      CardListTile(
                        title: 'Listening Stats',
                        icon: FlutterRemix.bar_chart_line,
                        isLast: true,
                        onTap: () => _controller.openListeningStats(context),
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
