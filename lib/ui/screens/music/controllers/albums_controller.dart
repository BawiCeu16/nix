import 'package:flutter/material.dart';
import 'package:nix/models/music/album.dart';
import 'package:nix/ui/widgets/common/cd_widget.dart';

enum AlbumSort { defaultOrder, aToZ, zToA }

/// Controller managing sorting computations and CD cover animation state for Albums screens.
class AlbumsPageController with ChangeNotifier {
  AlbumSort _sort = AlbumSort.defaultOrder;

  AlbumSort get sort => _sort;

  void setSort(AlbumSort newSort) {
    if (_sort == newSort) return;
    _sort = newSort;
    notifyListeners();
  }

  /// Sorts album list based on active [AlbumSort] option.
  List<Album> getSortedAlbums(List<Album> originalAlbums) {
    final List<Album> albums = List.from(originalAlbums);
    if (_sort == AlbumSort.aToZ) {
      albums.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sort == AlbumSort.zToA) {
      albums.sort((a, b) => b.title.compareTo(a.title));
    }
    return albums;
  }
}

/// Controller managing timed CD cover opening animation state for AlbumTracksPage.
class AlbumTracksController with ChangeNotifier {
  CDCoverState _cdState = CDCoverState.closed;

  CDCoverState get cdState => _cdState;

  void initializeCDAnimation() {
    _cdState = CDCoverState.closed;
    Future.delayed(const Duration(milliseconds: 400), () {
      _cdState = CDCoverState.halfOpen;
      notifyListeners();
    });
  }

  void setCDState(CDCoverState newState) {
    _cdState = newState;
    notifyListeners();
  }
}
