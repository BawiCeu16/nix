import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:material_3_expressive/material_3_expressive.dart'
    hide M3EButtonDecoration, M3EMotion;
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                M3EIconButton(
                                  variant: M3EIconButtonVariant.filled,
                                  size: M3EIconButtonSize.md,
                                  width: M3EIconButtonWidth.wide,
                                  icon: const Icon(FlutterRemix.bar_chart_fill),
                                  semanticLabel: "Stats",
                                  decoration: M3EIconButtonDecoration(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                    ),
                                    foregroundColor: WidgetStatePropertyAll(
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _controller.openListeningStats(context),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Stats',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                M3EIconButton(
                                  variant: M3EIconButtonVariant.filled,
                                  size: M3EIconButtonSize.md,
                                  width: M3EIconButtonWidth.wide,
                                  icon: const Icon(FlutterRemix.time_line),
                                  semanticLabel: "Recent",
                                  decoration: M3EIconButtonDecoration(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                    ),
                                    foregroundColor: WidgetStatePropertyAll(
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _controller.openRecentlyListened(context),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Recent',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                M3EIconButton(
                                  variant: M3EIconButtonVariant.filled,
                                  size: M3EIconButtonSize.md,
                                  width: M3EIconButtonWidth.wide,
                                  icon: const Icon(FlutterRemix.heart_3_fill),
                                  semanticLabel: "Favorites",
                                  decoration: M3EIconButtonDecoration(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                    ),
                                    foregroundColor: WidgetStatePropertyAll(
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _controller.openFavorites(context),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Favorites',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
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
