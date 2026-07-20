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
import 'package:nix/models/music/track.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:nix/models/music/artist.dart';
import 'package:nix/models/music/album.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/ui/widgets/common/nix_playlist_cover.dart';
import 'package:nix/ui/screens/music/artists_page.dart';
import 'package:nix/ui/screens/music/albums_page.dart';
import 'package:nix/ui/screens/music/playlist_view_page.dart';
import 'package:nix/ui/widgets/tiles/nix_choice_chip.dart';

enum SearchFilter { tracks, artists, playlists, albums }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  SearchFilter _selectedFilter = SearchFilter.tracks;
  List<Track> _searchResults = [];
  List<Artist> _searchArtists = [];
  List<Playlist> _searchPlaylists = [];
  List<Album> _searchAlbums = [];

  bool get _isCurrentFilterEmpty {
    switch (_selectedFilter) {
      case SearchFilter.tracks:
        return _searchResults.isEmpty;
      case SearchFilter.artists:
        return _searchArtists.isEmpty;
      case SearchFilter.playlists:
        return _searchPlaylists.isEmpty;
      case SearchFilter.albums:
        return _searchAlbums.isEmpty;
    }
  }

  void _onSearchChanged(String query, MusicProvider music) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchArtists = [];
        _searchPlaylists = [];
        _searchAlbums = [];
      });
      return;
    }
    setState(() {
      _searchResults = music.searchTracks(query);
      _searchArtists = music.searchArtists(query);
      _searchPlaylists = music.playlists
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _searchAlbums = music.searchAlbums(query);
    });
  }

  void _submitSearch(String query, SettingsProvider settings) {
    if (query.trim().isEmpty) return;
    settings.addSearchQuery(query.trim());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final music = context.watch<MusicProvider>();
    final settings = context.watch<SettingsProvider>();
    final brightness = Theme.of(context).brightness;
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
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
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
                        controller: _searchController,
                        hintText: "Search tracks, artists, albums...",
                        textInputAction: TextInputAction.search,
                        leading: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: const Icon(FlutterRemix.search_line),
                        ),
                        trailing: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(FlutterRemix.close_line),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('', music);
                              },
                            ),
                        ],
                        onChanged: (val) => _onSearchChanged(val, music),
                        onSubmitted: (val) => _submitSearch(
                          val,
                          context.read<SettingsProvider>(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Filter chips shown when searching
                if (_searchController.text.isNotEmpty)
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
                              groupValue: _selectedFilter,
                              onChanged: (val) =>
                                  setState(() => _selectedFilter = val),
                              isFirst: true,
                            ),
                            const SizedBox(width: 4),
                            NixChoiceChip<SearchFilter>(
                              label: 'Artists',
                              value: SearchFilter.artists,
                              groupValue: _selectedFilter,
                              onChanged: (val) =>
                                  setState(() => _selectedFilter = val),
                            ),
                            const SizedBox(width: 4),
                            NixChoiceChip<SearchFilter>(
                              label: 'Playlists',
                              value: SearchFilter.playlists,
                              groupValue: _selectedFilter,
                              onChanged: (val) =>
                                  setState(() => _selectedFilter = val),
                            ),
                            const SizedBox(width: 4),
                            NixChoiceChip<SearchFilter>(
                              label: 'Albums',
                              value: SearchFilter.albums,
                              groupValue: _selectedFilter,
                              onChanged: (val) =>
                                  setState(() => _selectedFilter = val),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Results or placeholder
                if (_searchController.text.isEmpty)
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () => NixDialog.show(
                                      title: "Clear Search History?",
                                      subtitle: "Remove all search history?",
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
                                                          rootNavigator: true,
                                                        ).pop(),
                                                    child: const Text("Cancel"),
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
                                                    child: const Text("Clear"),
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
                                      onPressed: () {
                                        _searchController.text = query;
                                        _searchController.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset: query.length,
                                              ),
                                            );
                                        _onSearchChanged(query, music);
                                      },
                                    ),
                                    onTap: () {
                                      _searchController.text = query;
                                      _onSearchChanged(query, music);
                                      _submitSearch(query, settings);
                                    },
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
                                                            rootNavigator: true,
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
                                                          rootNavigator: true,
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
                else if (_isCurrentFilterEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        "No results found.",
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else if (_selectedFilter == SearchFilter.tracks)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList.builder(
                      itemCount: _searchResults.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _searchResults.length) {
                          return const NixBottomSpacer();
                        }
                        final track = _searchResults[index];
                        return TrackTile(
                          track: track,
                          playlistContext: _searchResults,
                          isFirst: index == 0,
                          isLast: index == _searchResults.length - 1,
                        );
                      },
                    ),
                  )
                else if (_selectedFilter == SearchFilter.artists)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList.builder(
                      itemCount: _searchArtists.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _searchArtists.length) {
                          return const NixBottomSpacer();
                        }
                        final artist = _searchArtists[index];
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
                            isLast: index == _searchArtists.length - 1,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ArtistTracksPage(artistName: artist.name),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  )
                else if (_selectedFilter == SearchFilter.playlists)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList.builder(
                      itemCount: _searchPlaylists.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _searchPlaylists.length) {
                          return const NixBottomSpacer();
                        }
                        final playlist = _searchPlaylists[index];
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
                            isLast: index == _searchPlaylists.length - 1,
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
                else if (_selectedFilter == SearchFilter.albums)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList.builder(
                      itemCount: _searchAlbums.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _searchAlbums.length) {
                          return const NixBottomSpacer();
                        }
                        final album = _searchAlbums[index];
                        final albumTracks = music.getTracksByAlbum(album.title);
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
                            isLast: index == _searchAlbums.length - 1,
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
  }
}
