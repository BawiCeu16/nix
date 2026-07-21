import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/models/music/album.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/screens/music/albums_page.dart';

enum AlbumSort { name, artist, trackCount }

class AlbumsPageController extends ChangeNotifier {
  AlbumSort _sort = AlbumSort.name;
  AlbumSort get sort => _sort;

  void setSort(AlbumSort newSort) {
    if (_sort != newSort) {
      _sort = newSort;
      notifyListeners();
    }
  }

  List<Album> getSortedAlbums(List<Album> albums) {
    final list = List<Album>.from(albums);
    switch (_sort) {
      case AlbumSort.name:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case AlbumSort.artist:
        list.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case AlbumSort.trackCount:
        list.sort((a, b) => b.numOfSongs.compareTo(a.numOfSongs));
        break;
    }
    return list;
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

  void playAlbumTrack(
    BuildContext context,
    Track track,
    List<Track> albumTracks,
    String albumTitle,
  ) {
    final audio = context.read<CurrentMusicProvider>();
    final pl = Playlist(
      id: 'album_$albumTitle',
      name: albumTitle,
      tracks: albumTracks,
      createdAt: DateTime.now(),
    );
    audio.playTrack(track, playlist: pl);
  }

  void shuffleAlbum(
    BuildContext context,
    List<Track> albumTracks,
    String albumTitle,
  ) {
    if (albumTracks.isEmpty) return;
    final audio = context.read<CurrentMusicProvider>();
    final pl = Playlist(
      id: 'album_$albumTitle',
      name: albumTitle,
      tracks: albumTracks,
      createdAt: DateTime.now(),
    );
    final shuffled = List<Track>.from(albumTracks)..shuffle();
    if (!audio.isShuffleEnabled) audio.toggleShuffle();
    audio.playTrack(shuffled.first, playlist: pl);
  }
}
