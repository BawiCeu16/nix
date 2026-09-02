import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/tiles/track_tile.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/buttons/expressive_button.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/widgets/common/nix_playlist_cover.dart';
import 'package:nix/ui/screens/music/artists_page.dart';
import 'package:nix/ui/screens/music/albums_page.dart';
import 'package:nix/ui/screens/music/playlist_view_page.dart';
import 'package:nix/ui/widgets/tiles/nix_choice_chip.dart';
import 'package:nix/ui/screens/main/controllers/search_controller.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchPageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final music = context.watch<MusicProvider>();
    final settings = context.watch<SettingsProvider>();
    final brightness = Theme.of(context).brightness;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: brightness == Brightness.dark
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                ),
          child: Scaffold(
            backgroundColor: colorScheme.surfaceContainer,
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              bottom: false,
              child: NixScrollbar(
                child: CustomScrollView(
                  scrollCacheExtent: const .pixels(600.0),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverAppBar(
            centerTitle: true,
                      systemOverlayStyle: brightness == Brightness.dark
                          ? SystemUiOverlayStyle.light.copyWith(
                              statusBarColor: Colors.transparent,
                            )
                          : SystemUiOverlayStyle.dark.copyWith(
                              statusBarColor: Colors.transparent,
                            ),
                      floating: false,
                      snap: false,
                      scrolledUnderElevation: 0,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      expandedHeight: 30,
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(60),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          child: SearchBar(
                            backgroundColor: WidgetStatePropertyAll(
                              colorScheme.surface,
                            ),
                            elevation: const WidgetStatePropertyAll(0),
                            controller: _controller.searchInputController,
                            hintText: "Search tracks, artists, albums...",
                            textInputAction: TextInputAction.search,
                            leading: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: const Icon(FlutterRemix.search_line),
                            ),
                            trailing: [
                              if (_controller
                                  .searchInputController
                                  .text
                                  .isNotEmpty)
                                IconButton(
                                  icon: const Icon(FlutterRemix.close_line),
                                  onPressed: () =>
                                      _controller.clearSearch(music),
                                ),
                            ],
                            onChanged: (val) =>
                                _controller.onSearchChanged(val, music),
                            onSubmitted: (val) =>
                                _controller.submitSearch(val, settings),
                          ),
                        ),
                      ),
                    ),

                    // Filter chips shown when searching
                    if (_controller.searchInputController.text.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                NixChoiceChip<SearchFilter>(
                                  label: 'Tracks',
                                  value: SearchFilter.tracks,
                                  groupValue: _controller.selectedFilter,
                                  onChanged: (val) =>
                                      _controller.setFilter(val),
                                  isFirst: true,
                                ),
                                const SizedBox(width: 4),
                                NixChoiceChip<SearchFilter>(
                                  label: 'Artists',
                                  value: SearchFilter.artists,
                                  groupValue: _controller.selectedFilter,
                                  onChanged: (val) =>
                                      _controller.setFilter(val),
                                ),
                                const SizedBox(width: 4),
                                NixChoiceChip<SearchFilter>(
                                  label: 'Playlists',
                                  value: SearchFilter.playlists,
                                  groupValue: _controller.selectedFilter,
                                  onChanged: (val) =>
                                      _controller.setFilter(val),
                                ),
                                const SizedBox(width: 4),
                                NixChoiceChip<SearchFilter>(
                                  label: 'Albums',
                                  value: SearchFilter.albums,
                                  groupValue: _controller.selectedFilter,
                                  onChanged: (val) =>
                                      _controller.setFilter(val),
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Results or placeholder
                    if (_controller.searchInputController.text.isEmpty)
                      settings.searchHistory.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  "Type something to search...",
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Recent",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      TextButton(
                                        onPressed: () => NixDialog.show(
                                          title: "Clear Search History?",
                                          subtitle:
                                              "Remove all search history?",
                                          children: [
                                            Builder(
                                              builder: (dialogContext) {
                                                return Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          ExpressiveToneButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  dialogContext,
                                                                  rootNavigator:
                                                                      true,
                                                                ).pop(),
                                                            child: const Text(
                                                              "Cancel",
                                                            ),
                                                          ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: ExpressiveButton(
                                                        onPressed: () {
                                                          settings
                                                              .clearSearchHistory();
                                                          Navigator.of(
                                                            dialogContext,
                                                            rootNavigator: true,
                                                          ).pop();
                                                        },
                                                        child: const Text(
                                                          "Clear",
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                          context: context,
                                        ),
                                        child: const Text("Clear All"),
                                      ),
                                    ],
                                  ),
                                  ...settings.searchHistory.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final query = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 1.5,
                                      ),
                                      child: CardListTile(
                                        title: query,
                                        icon: FlutterRemix.history_line,
                                        isFirst: index == 0,
                                        isLast:
                                            index ==
                                            settings.searchHistory.length - 1,
                                        trailing: IconButton(
                                          icon: const Icon(
                                            FlutterRemix.arrow_left_up_line,
                                            size: 18,
                                          ),
                                          onPressed: () => _controller.setQuery(
                                            query,
                                            music,
                                            settings,
                                          ),
                                        ),
                                        onTap: () => _controller.setQuery(
                                          query,
                                          music,
                                          settings,
                                        ),
                                        onLongPress: () {
                                          NixDialog.show(
                                            context: context,
                                            title: "Delete Search?",
                                            subtitle:
                                                "Remove '$query' from history?",
                                            children: [
                                              Builder(
                                                builder: (dialogContext) {
                                                  return Row(
                                                    children: [
                                                      Expanded(
                                                        child: ExpressiveToneButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                dialogContext,
                                                                rootNavigator:
                                                                    true,
                                                              ).pop(),
                                                          child: const Text(
                                                            "Cancel",
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: ExpressiveButton(
                                                          onPressed: () {
                                                            settings
                                                                .removeSearchQuery(
                                                                  query,
                                                                );
                                                            Navigator.of(
                                                              dialogContext,
                                                              rootNavigator:
                                                                  true,
                                                            ).pop();
                                                          },
                                                          child: const Text(
                                                            "Delete",
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    );
                                  }),
                                  const NixBottomSpacer(),
                                ]),
                              ),
                            )
                    else if (_controller.isCurrentFilterEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            "No results found.",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else if (_controller.selectedFilter == SearchFilter.tracks)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverList.builder(
                          itemCount: _controller.searchResults.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _controller.searchResults.length) {
                              return const NixBottomSpacer();
                            }
                            final track = _controller.searchResults[index];
                            return TrackTile(
                              track: track,
                              playlistContext: _controller.searchResults,
                              isFirst: index == 0,
                              isLast:
                                  index == _controller.searchResults.length - 1,
                            );
                          },
                        ),
                      )
                    else if (_controller.selectedFilter == SearchFilter.artists)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverList.builder(
                          itemCount: _controller.searchArtists.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _controller.searchArtists.length) {
                              return const NixBottomSpacer();
                            }
                            final artist = _controller.searchArtists[index];
                            final artistTracks = music.getTracksByArtist(
                              artist.name,
                            );
                            final firstTrackId = artistTracks.isNotEmpty
                                ? artistTracks.first.id
                                : 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: CardListTile(
                                title: artist.name,
                                subtitle:
                                    '${artist.numberOfTracks} tracks • ${artist.numberOfAlbums} albums',
                                leading: NixArtwork(
                                  id: firstTrackId,
                                  type: ArtworkType.AUDIO,
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                isFirst: index == 0,
                                isLast:
                                    index ==
                                    _controller.searchArtists.length - 1,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ArtistTracksPage(
                                        artistName: artist.name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      )
                    else if (_controller.selectedFilter ==
                        SearchFilter.playlists)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverList.builder(
                          itemCount: _controller.searchPlaylists.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _controller.searchPlaylists.length) {
                              return const NixBottomSpacer();
                            }
                            final playlist = _controller.searchPlaylists[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: CardListTile(
                                title: playlist.name,
                                subtitle: '${playlist.tracks.length} tracks',
                                leading: NixPlaylistCover(
                                  playlist: playlist,
                                  size: 48,
                                ),
                                isFirst: index == 0,
                                isLast:
                                    index ==
                                    _controller.searchPlaylists.length - 1,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PlaylistViewPage(
                                        playlistName: playlist.name,
                                        playlistId: playlist.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      )
                    else if (_controller.selectedFilter == SearchFilter.albums)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverList.builder(
                          itemCount: _controller.searchAlbums.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _controller.searchAlbums.length) {
                              return const NixBottomSpacer();
                            }
                            final album = _controller.searchAlbums[index];
                            final albumTracks = music.getTracksByAlbum(
                              album.title,
                            );
                            final firstTrackId = albumTracks.isNotEmpty
                                ? albumTracks.first.id
                                : 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: CardListTile(
                                title: album.title,
                                subtitle:
                                    '${album.artist} • ${album.numOfSongs} songs',
                                leading: NixArtwork(
                                  id: firstTrackId,
                                  type: ArtworkType.AUDIO,
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isFirst: index == 0,
                                isLast:
                                    index ==
                                    _controller.searchAlbums.length - 1,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AlbumTracksPage(
                                        albumTitle: album.title,
                                        albumArtist: album.artist,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
