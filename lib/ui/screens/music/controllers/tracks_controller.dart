import 'package:flutter/material.dart';
import 'package:nix/models/music/track.dart';

enum TrackSort { title, duration, dateAdded, artist, album }

class TracksPageController extends ChangeNotifier {
  TrackSort _sort = TrackSort.title;
  TrackSort get sort => _sort;

  bool _isAscending = true;
  bool get isAscending => _isAscending;

  void setSort(TrackSort newSort) {
    if (_sort != newSort) {
      _sort = newSort;
      notifyListeners();
    }
  }

  void toggleOrder() {
    _isAscending = !_isAscending;
    notifyListeners();
  }

  List<Track> getSortedTracks(List<Track> tracks) {
    final list = List<Track>.from(tracks);
    switch (_sort) {
      case TrackSort.title:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case TrackSort.duration:
        list.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case TrackSort.dateAdded:
        list.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;
      case TrackSort.artist:
        list.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case TrackSort.album:
        list.sort((a, b) => a.album.compareTo(b.album));
        break;
    }
    
    if (!_isAscending) {
      return list.reversed.toList();
    }
    
    return list;
  }
}
