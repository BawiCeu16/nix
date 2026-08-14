import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/models/music/artist.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/screens/music/artists_page.dart';

enum ArtistSort { name, trackCount }

class ArtistsPageController extends ChangeNotifier {
  ArtistSort _sort = ArtistSort.name;
  ArtistSort get sort => _sort;

  bool _isAscending = true;
  bool get isAscending => _isAscending;

  void setSort(ArtistSort newSort) {
    if (_sort != newSort) {
      _sort = newSort;
      notifyListeners();
    }
  }

  void toggleOrder() {
    _isAscending = !_isAscending;
    notifyListeners();
  }

  List<Artist> getSortedArtists(List<Artist> artists) {
    final list = List<Artist>.from(artists);
    switch (_sort) {
      case ArtistSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ArtistSort.trackCount:
        list.sort((a, b) => b.numberOfTracks.compareTo(a.numberOfTracks));
        break;
    }
    
    if (!_isAscending) {
      return list.reversed.toList();
    }
    
    return list;
  }

  void openArtistDetails(BuildContext context, String artistName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistTracksPage(artistName: artistName),
      ),
    );
  }

  void playArtistTrack(
    BuildContext context,
    Track track,
    List<Track> artistTracks,
    String artistName,
  ) {
    final audio = context.read<CurrentMusicProvider>();
    final pl = Playlist(
      id: 'artist_$artistName',
      name: artistName,
      tracks: artistTracks,
      createdAt: DateTime.now(),
    );
    audio.playTrack(track, playlist: pl);
  }

  void shuffleArtist(
    BuildContext context,
    List<Track> artistTracks,
    String artistName,
  ) {
    if (artistTracks.isEmpty) return;
    final audio = context.read<CurrentMusicProvider>();
    final pl = Playlist(
      id: 'artist_$artistName',
      name: artistName,
      tracks: artistTracks,
      createdAt: DateTime.now(),
    );
    final shuffled = List<Track>.from(artistTracks)..shuffle();
    if (!audio.isShuffleEnabled) audio.toggleShuffle();
    audio.playTrack(shuffled.first, playlist: pl);
  }
}
