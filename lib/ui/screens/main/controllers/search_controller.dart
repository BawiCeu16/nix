import 'package:flutter/material.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/artist.dart';
import 'package:nix/models/music/album.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';

enum SearchFilter { tracks, artists, playlists, albums }

/// Controller managing search state, filtering, and query execution for SearchPage.
class SearchPageController with ChangeNotifier {
  final TextEditingController searchInputController = TextEditingController();
  SearchFilter _selectedFilter = SearchFilter.tracks;

  List<Track> _searchResults = [];
  List<Artist> _searchArtists = [];
  List<Playlist> _searchPlaylists = [];
  List<Album> _searchAlbums = [];

  SearchFilter get selectedFilter => _selectedFilter;
  List<Track> get searchResults => _searchResults;
  List<Artist> get searchArtists => _searchArtists;
  List<Playlist> get searchPlaylists => _searchPlaylists;
  List<Album> get searchAlbums => _searchAlbums;

  bool get isCurrentFilterEmpty {
    switch (_selectedFilter) {
      case SearchFilter.tracks:
        return _searchResults.isEmpty;
      case SearchFilter.artists:
        return _searchArtists.isEmpty;
      case SearchFilter.playlists:
        return _searchPlaylists.isEmpty;
      case SearchFilter.albums:
        return _searchAlbums.isEmpty;
    }
  }

  void setFilter(SearchFilter filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  void onSearchChanged(String query, MusicProvider music) {
    if (query.isEmpty) {
      _searchResults = [];
      _searchArtists = [];
      _searchPlaylists = [];
      _searchAlbums = [];
      notifyListeners();
      return;
    }

    _searchResults = music.searchTracks(query);
    _searchArtists = music.searchArtists(query);
    _searchPlaylists = music.playlists
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    _searchAlbums = music.searchAlbums(query);
    notifyListeners();
  }

  void submitSearch(String query, SettingsProvider settings) {
    if (query.trim().isEmpty) return;
    settings.addSearchQuery(query.trim());
  }

  void clearSearch(MusicProvider music) {
    searchInputController.clear();
    onSearchChanged('', music);
  }

  void setQuery(String query, MusicProvider music, SettingsProvider settings) {
    searchInputController.text = query;
    searchInputController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    onSearchChanged(query, music);
    submitSearch(query, settings);
  }

  @override
  void dispose() {
    searchInputController.dispose();
    super.dispose();
  }
}
