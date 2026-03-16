import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:nix/models/music/song.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];

  void _onSearchChanged(String query, MusicProvider music) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _searchResults = music.searchSongs(query);
    });
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: false,
            snap: false,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 30,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: SearchBar(
                  backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
                  elevation: const WidgetStatePropertyAll(0),
                  controller: _searchController,
                  hintText: "Search songs, artists, albums...",
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
                ),
              ),
            ),
          ),

          // Results or placeholder
          if (_searchResults.isEmpty && _searchController.text.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  "Type something to search...",
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else if (_searchResults.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  "No results found.",
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList.builder(
                itemCount: _searchResults.length + 1,
                itemBuilder: (context, index) {
                  if (index == _searchResults.length)
                    return const SizedBox(height: 120);
                  final song = _searchResults[index];
                  return TrackTile(
                    track: song,
                    playlistContext: _searchResults,
                    isFirst: index == 0,
                    isLast: index == _searchResults.length - 1,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
