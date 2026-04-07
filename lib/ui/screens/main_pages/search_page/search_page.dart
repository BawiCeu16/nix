import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/list_item/track_tile.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/buttons/expressive_button.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
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
                      hintText: "Search songs, artists, albums...",
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
                      onSubmitted: (val) =>
                          _submitSearch(val, context.read<SettingsProvider>()),
                    ),
                  ),
                ),
              ),

              // Results or placeholder
              if (_searchResults.isEmpty && _searchController.text.isEmpty)
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    final history = settings.searchHistory;
                    if (history.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            "Type something to search...",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Recent",
                                style: Theme.of(context).textTheme.titleSmall
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
                                                onPressed: () => Navigator.of(
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
                                                  settings.clearSearchHistory();
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
                          ...history.asMap().entries.map((entry) {
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
                                isLast: index == history.length - 1,
                                trailing: IconButton(
                                  icon: const Icon(
                                    FlutterRemix.arrow_left_up_line,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.text = query;
                                    _searchController.selection =
                                        TextSelection.fromPosition(
                                          TextPosition(offset: query.length),
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
                                    subtitle: "Remove '$query' from history?",
                                    children: [
                                      Builder(
                                        builder: (dialogContext) {
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: ExpressiveToneButton(
                                                  onPressed: () => Navigator.of(
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
                                                    settings.removeSearchQuery(
                                                      query,
                                                    );
                                                    Navigator.of(
                                                      dialogContext,
                                                      rootNavigator: true,
                                                    ).pop();
                                                  },
                                                  child: const Text("Delete"),
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
                        ]),
                      ),
                    );
                  },
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
                      if (index == _searchResults.length) {
                        return SizedBox(
                          height:
                              120 + MediaQuery.of(context).viewInsets.bottom,
                        );
                      }
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
        ),
      ),
    );
  }
}
