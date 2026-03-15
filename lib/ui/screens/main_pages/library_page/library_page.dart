import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import '../../music_pages/albums_page.dart';
import '../../music_pages/artists_page.dart';
import '../../music_pages/playlists_page.dart';
import '../../music_pages/songs_page.dart';
import '../../second_pages/profile_page.dart';
import '../../second_pages/settings_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Library'),
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
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              physics: const BouncingScrollPhysics(),
              children: [
                // User Profile
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: Theme.of(context).colorScheme.surface,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: const Text("Nix User"),
                  subtitle: const Text("nix user"),
                  onTap: () => _push(context, const ProfilePage()),
                ),
                const SizedBox(height: 10),

                // Dynamic stats
                CardListTile(
                  title: 'Top Listened',
                  icon: FlutterRemix.fire_fill,
                  subtitle: '${music.topPlayed.songs.length} tracks',
                  isFirst: true,
                  onTap: () => _push(
                    context,
                    SongsPage(
                      title: 'Top Listened',
                      songsSource: () =>
                          context.read<MusicProvider>().topPlayed.songs,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                CardListTile(
                  title: 'Recently Listened',
                  icon: FlutterRemix.time_line,
                  subtitle: '${music.recentlyPlayed.songs.length} tracks',
                  onTap: () => _push(
                    context,
                    SongsPage(
                      title: 'Recently Listened',
                      songsSource: () =>
                          context.read<MusicProvider>().recentlyPlayed.songs,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                CardListTile(
                  title: 'Favorites',
                  icon: FlutterRemix.heart_3_fill,
                  subtitle: '${music.favorites.songs.length} tracks',
                  isLast: true,
                  onTap: () => _push(
                    context,
                    SongsPage(
                      title: 'Favorites',
                      songsSource: () =>
                          context.read<MusicProvider>().favorites.songs,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Media categories
                CardListTile(
                  title: 'Artists',
                  icon: FlutterRemix.user_4_line,
                  subtitle: '${music.artists.length} artists',
                  isFirst: true,
                  onTap: () => _push(context, const ArtistsPage()),
                ),
                const SizedBox(height: 3),
                CardListTile(
                  title: 'Albums',
                  icon: FlutterRemix.disc_line,
                  subtitle: '${music.albums.length} albums',
                  onTap: () => _push(context, const AlbumsPage()),
                ),
                const SizedBox(height: 3),
                CardListTile(
                  title: 'Playlists',
                  icon: FlutterRemix.play_list_line,
                  subtitle: '${music.playlists.length} playlists',
                  onTap: () => _push(context, const PlaylistsPage()),
                ),
                const SizedBox(height: 3),
                CardListTile(
                  title: 'All Songs',
                  icon: FlutterRemix.music_2_line,
                  subtitle: '${music.songs.length} tracks',
                  isLast: true,
                  onTap: () => _push(
                    context,
                    SongsPage(
                      title: 'All Songs',
                      songsSource: () => context.read<MusicProvider>().songs,
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }
}
