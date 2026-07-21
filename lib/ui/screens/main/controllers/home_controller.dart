import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/ui/screens/profile_page.dart';
import 'package:nix/ui/screens/music/tracks_page.dart';
import 'package:nix/ui/screens/music/albums_page.dart';

class HomePageController extends ChangeNotifier {
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  Future<void> refreshLibrary(BuildContext context) async {
    await context.read<MusicProvider>().scanDevice();
  }

  void openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  void openAllSongs(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TracksPage(
          title: 'All Songs',
          tracksSource: () => context.read<MusicProvider>().tracks,
        ),
      ),
    );
  }

  void openAlbums(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlbumsPage()),
    );
  }

  void openRecentlyListened(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TracksPage(
          title: 'Recently Listened',
          tracksSource: () => context.read<MusicProvider>().recentlyPlayed.tracks,
        ),
      ),
    );
  }

  void playRecentTrack(BuildContext context, Track track, List<Track> allRecents) {
    final currentMusic = context.read<CurrentMusicProvider>();
    final pl = Playlist(
      id: 'recently_played',
      name: 'Recently Listened',
      tracks: allRecents,
      createdAt: DateTime.now(),
    );
    currentMusic.playTrack(track, playlist: pl);
  }

  void openAlbumDetails(BuildContext context, String albumTitle, String albumArtist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumTracksPage(
          albumTitle: albumTitle,
          albumArtist: albumArtist,
        ),
      ),
    );
  }
}
