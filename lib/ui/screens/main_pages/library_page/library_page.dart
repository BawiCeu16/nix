import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import '../../music_pages/albums_page.dart';
import '../../music_pages/artists_page.dart';
import '../../music_pages/playlists_page.dart';
import '../../music_pages/tracks_page.dart';
import '../../second_pages/profile_page.dart';
import '../../second_pages/settings_page.dart';
import 'package:nix/ui/widgets/common/nix_refreshable_list.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

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
            onPressed: () => _push(context, const SettingsPage()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Consumer<MusicProvider>(
          builder: (context, music, child) {
            return NixRefreshableList(
              onRefresh: () async => await music.scanDevice(),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  // User Profile
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    tileColor: Theme.of(context).colorScheme.surface,
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: UserProvider
                          .avatarColors[user.avatarIndex]
                          .withValues(alpha: 0.2),
                      child: Icon(
                        UserProvider.avatarIcons[user.avatarIndex],
                        color: UserProvider.avatarColors[user.avatarIndex],
                        size: 30,
                      ),
                    ),
                    title: Text(user.userName),
                    subtitle: const Text("View your music profile"),
                    onTap: () => _push(context, const ProfilePage()),
                  ),
                  const SizedBox(height: 10),
                  const NixSectionHeader(title: 'Personal', topPadding: 16),

                  // Dynamic stats
                  CardListTile(
                    title: 'Top Listened',
                    icon: FlutterRemix.fire_fill,
                    subtitle: '${music.topPlayed.tracks.length} tracks',
                    isFirst: true,
                    onTap: () => _push(
                      context,
                      TracksPage(
                        title: 'Top Listened',
                        tracksSource: () =>
                            context.read<MusicProvider>().topPlayed.tracks,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2.5),
                  CardListTile(
                    title: 'Recently Listened',
                    icon: FlutterRemix.time_line,
                    subtitle: '${music.recentlyPlayed.tracks.length} tracks',
                    onTap: () => _push(
                      context,
                      TracksPage(
                        title: 'Recently Listened',
                        tracksSource: () =>
                            context.read<MusicProvider>().recentlyPlayed.tracks,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2.5),
                  CardListTile(
                    title: 'Favorites',
                    icon: FlutterRemix.heart_3_fill,
                    subtitle: '${music.favorites.tracks.length} tracks',
                    isLast: true,
                    onTap: () => _push(
                      context,
                      TracksPage(
                        title: 'Favorites',
                        tracksSource: () =>
                            context.read<MusicProvider>().favorites.tracks,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const NixSectionHeader(title: 'Library', topPadding: 0),

                  // Media categories
                  CardListTile(
                    title: 'Artists',
                    icon: FlutterRemix.user_4_line,
                    subtitle: '${music.artists.length} artists',
                    isFirst: true,
                    onTap: () => _push(context, const ArtistsPage()),
                  ),
                  const SizedBox(height: 2.5),
                  CardListTile(
                    title: 'Albums',
                    icon: FlutterRemix.disc_line,
                    subtitle: '${music.albums.length} albums',
                    onTap: () => _push(context, const AlbumsPage()),
                  ),
                  const SizedBox(height: 2.5),
                  CardListTile(
                    title: 'Playlists',
                    icon: FlutterRemix.play_list_line,
                    subtitle: '${music.playlists.length} playlists',
                    onTap: () => _push(context, const PlaylistsPage()),
                  ),
                  const SizedBox(height: 2.5),
                  CardListTile(
                    title: 'All Tracks',
                    icon: FlutterRemix.music_2_line,
                    subtitle: '${music.tracks.length} tracks',
                    isLast: true,
                    onTap: () => _push(
                      context,
                      TracksPage(
                        title: 'All Tracks',
                        tracksSource: () =>
                            context.read<MusicProvider>().tracks,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
