import 'package:flutter/material.dart';
import 'package:nix/models/music/track.dart';

enum TrackSort { defaultOrder, aToZ, zToA, duration }

class TracksPageController extends ChangeNotifier {
  TrackSort _sort = TrackSort.defaultOrder;
  TrackSort get sort => _sort;

  void setSort(TrackSort newSort) {
    if (_sort != newSort) {
      _sort = newSort;
      notifyListeners();
    }
  }

  List<Track> getSortedTracks(List<Track> tracks) {
    final list = List<Track>.from(tracks);
    switch (_sort) {
      case TrackSort.defaultOrder:
        break;
      case TrackSort.aToZ:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case TrackSort.zToA:
        list.sort((a, b) => b.title.compareTo(a.title));
        break;
      case TrackSort.duration:
        list.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }
    return list;
  }
}
