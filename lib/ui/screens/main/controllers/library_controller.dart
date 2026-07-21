import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/screens/settings/settings_page.dart';
import 'package:nix/ui/screens/profile_page.dart';
import 'package:nix/ui/screens/music/tracks_page.dart';
import 'package:nix/ui/screens/music/artists_page.dart';
import 'package:nix/ui/screens/music/albums_page.dart';
import 'package:nix/ui/screens/music/playlists_page.dart';

class LibraryPageController extends ChangeNotifier {
  Future<void> refreshLibrary(BuildContext context) async {
    await context.read<MusicProvider>().scanDevice();
  }

  void pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void openSettings(BuildContext context) {
    pushPage(context, const SettingsPage());
  }

  void openProfile(BuildContext context) {
    pushPage(context, const ProfilePage());
  }

  void openTopListened(BuildContext context) {
    pushPage(
      context,
      TracksPage(
        title: 'Top Listened',
        tracksSource: () => context.read<MusicProvider>().topPlayed.tracks,
      ),
    );
  }

  void openRecentlyListened(BuildContext context) {
    pushPage(
      context,
      TracksPage(
        title: 'Recently Listened',
        tracksSource: () => context.read<MusicProvider>().recentlyPlayed.tracks,
      ),
    );
  }

  void openFavorites(BuildContext context) {
    pushPage(
      context,
      TracksPage(
        title: 'Favorites',
        tracksSource: () => context.read<MusicProvider>().favorites.tracks,
      ),
    );
  }

  void openArtists(BuildContext context) {
    pushPage(context, const ArtistsPage());
  }

  void openAlbums(BuildContext context) {
    pushPage(context, const AlbumsPage());
  }

  void openPlaylists(BuildContext context) {
    pushPage(context, const PlaylistsPage());
  }

  void openAllTracks(BuildContext context) {
    pushPage(
      context,
      TracksPage(
        title: 'All Tracks',
        tracksSource: () => context.read<MusicProvider>().tracks,
      ),
    );
  }
}
