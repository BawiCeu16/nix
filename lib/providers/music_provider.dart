import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/album.dart';
import 'package:nix/models/music/artist.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/services/media_library_service.dart';
import 'package:nix/services/playlist_repository.dart';

/// Reactive provider managing device audio tracks, albums, artists, user playlists, and caches.
class MusicProvider extends ChangeNotifier {
  final MediaLibraryService _libraryService = MediaLibraryService();
  final PlaylistRepository _playlistRepo = PlaylistRepository();

  List<Track> _tracks = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  Map<String, int> _albumFirstTrackId = {};
  final List<Playlist> _playlists = [];

  bool _isLoading = false;
  final bool _hasScanned = false;
  String? _error;
  DateTime? _lastScanned;

  Playlist? _recentlyPlayedCache;
  Playlist? _topPlayedCache;
  Playlist? _favoritesCache;
  StreamSubscription<Track>? _playbackSubscription;
  CurrentMusicProvider? _currentMusic;

  // Getters
  List<Track> get tracks => _tracks;
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  Map<String, int> get albumFirstTrackId => _albumFirstTrackId;
  List<Playlist> get playlists => _playlists;
  DateTime? get lastScanned => _lastScanned;
  bool get isLoading => _isLoading;
  bool get hasScanned => _hasScanned;
  String? get error => _error;

  /// Refreshes cached playlists (Recently Listened, Top Listened, Favorites).
  Future<void> refreshCaches() async {
    await _rebuildCaches();
    notifyListeners();
  }

  Playlist get recentlyPlayed =>
      _recentlyPlayedCache ??
      Playlist(
        id: 'recently_played',
        name: 'Recently Listened',
        tracks: [],
        createdAt: DateTime.now(),
      );

  Playlist get topPlayed =>
      _topPlayedCache ??
      Playlist(
        id: 'top_played',
        name: 'Top Listened',
        tracks: [],
        createdAt: DateTime.now(),
      );

  Playlist get favorites =>
      _favoritesCache ??
      Playlist(
        id: 'favorites',
        name: 'Favorites',
        tracks: [],
        createdAt: DateTime.now(),
      );

  Playlist _calculateRecentlyPlayed() {
    if (!Hive.isBoxOpen(HiveKeys.playHistoryBox)) {
      return Playlist(
        id: 'recently_played',
        name: 'Recently Listened',
        tracks: [],
        createdAt: DateTime.now(),
      );
    }
    final historyBox = Hive.box<int>(HiveKeys.playHistoryBox);
    final history = historyBox.toMap();
    final sortedEntries = history.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recentTrackIds = sortedEntries.take(50).map((e) => e.key).toSet();
    final recentTracks = _tracks
        .where((s) => recentTrackIds.contains(s.id))
        .toList();

    recentTracks.sort((a, b) {
      final timeA = historyBox.get(a.id) ?? 0;
      final timeB = historyBox.get(b.id) ?? 0;
      return timeB.compareTo(timeA);
    });

    return Playlist(
      id: 'recently_played',
      name: 'Recently Listened',
      tracks: recentTracks,
      createdAt: DateTime.now(),
    );
  }

  Playlist _calculateTopPlayed() {
    if (!Hive.isBoxOpen(HiveKeys.playCountsBox)) {
      return Playlist(
        id: 'top_played',
        name: 'Top Listened',
        tracks: [],
        createdAt: DateTime.now(),
      );
    }
    final countsBox = Hive.box<int>(HiveKeys.playCountsBox);
    final counts = countsBox.toMap();
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topTrackIds = sortedEntries.take(50).map((e) => e.key).toSet();
    final topTracks = _tracks.where((s) => topTrackIds.contains(s.id)).toList();

    topTracks.sort((a, b) {
      final countA = countsBox.get(a.id) ?? 0;
      final countB = countsBox.get(b.id) ?? 0;
      return countB.compareTo(countA);
    });

    return Playlist(
      id: 'top_played',
      name: 'Top Listened',
      tracks: topTracks,
      createdAt: DateTime.now(),
    );
  }

  Playlist _calculateFavorites() {
    if (!Hive.isBoxOpen(HiveKeys.favoritesBox)) {
      return Playlist(
        id: 'favorites',
        name: 'Favorites',
        tracks: [],
        createdAt: DateTime.now(),
      );
    }
    final favoritesBox = Hive.box<int>(HiveKeys.favoritesBox);
    final entries = favoritesBox.toMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final orderedIds = entries.map((e) => e.key as int).toList();
    final trackMap = {for (final s in _tracks) s.id: s};
    final favoriteTracks = orderedIds
        .where((id) => trackMap.containsKey(id))
        .map((id) => trackMap[id]!)
        .toList();

    return Playlist(
      id: 'favorites',
      name: 'Favorites',
      tracks: favoriteTracks,
      createdAt: DateTime.now(),
    );
  }

  /// Initializes subscriptions and triggers the initial media scan.
  Future<void> init({
    List<String>? customFolders,
    CurrentMusicProvider? currentMusic,
  }) async {
    if (currentMusic != null) {
      _currentMusic = currentMusic;
      _playbackSubscription?.cancel();
      _playbackSubscription = currentMusic.onTrackPlayedStream.listen((_) {
        refreshCaches();
      });
    }
    if (Hive.isBoxOpen(HiveKeys.favoritesBox)) {
      Hive.box<int>(HiveKeys.favoritesBox).watch().listen((_) {
        _favoritesCache = _calculateFavorites();
        notifyListeners();
      });
    }

    await scanDevice(customFolders: customFolders);
    if (_currentMusic != null) {
      _currentMusic!.updateLibrary(_tracks);
    }
  }

  /// Completely resets the music library by clearing Hive boxes and re-scanning.
  Future<void> resetLibrary() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (Hive.isBoxOpen(HiveKeys.playHistoryBox)) {
        await Hive.box<int>(HiveKeys.playHistoryBox).clear();
      }
      if (Hive.isBoxOpen(HiveKeys.playCountsBox)) {
        await Hive.box<int>(HiveKeys.playCountsBox).clear();
      }
      if (Hive.isBoxOpen(HiveKeys.favoritesBox)) {
        await Hive.box<int>(HiveKeys.favoritesBox).clear();
      }
      await _playlistRepo.clearAll();

      _isLoading = false;
      await scanDevice();
    } catch (e) {
      debugPrint('Error resetting library: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Scans the device for valid audio files and builds the library state via [MediaLibraryService].
  Future<void> scanDevice({List<String>? customFolders}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final parsed = await _libraryService.scanDevice(
        customFolders: customFolders,
      );

      _tracks = parsed.tracks;
      _albums = parsed.albums;
      _artists = parsed.artists;
      _albumFirstTrackId = parsed.albumFirstTrackId;

      _loadPlaylists();
      await _rebuildCaches();
      _lastScanned = DateTime.now();
    } catch (e) {
      _error = 'Failed to scan device: $e';
      debugPrint('Error querying MediaStore: $e');
    }

    _isLoading = false;
    if (_currentMusic != null) {
      _currentMusic!.updateLibrary(_tracks);
    }
    notifyListeners();
  }

  Future<void> _rebuildCaches() async {
    final results = await Future.wait([
      Future(() => _calculateRecentlyPlayed()),
      Future(() => _calculateTopPlayed()),
      Future(() => _calculateFavorites()),
    ]);
    _recentlyPlayedCache = results[0];
    _topPlayedCache = results[1];
    _favoritesCache = results[2];
  }

  void _loadPlaylists() {
    _playlists.clear();
    _playlists.addAll(_playlistRepo.loadPlaylists(_tracks));
  }

  // Favorites management
  bool isFavorite(Track track) {
    if (!Hive.isBoxOpen(HiveKeys.favoritesBox)) return false;
    return Hive.box<int>(HiveKeys.favoritesBox).containsKey(track.id);
  }

  /// Toggles the favorite status for a [track].
  Future<void> toggleFavorite(Track track) async {
    final box = Hive.box<int>(HiveKeys.favoritesBox);

    if (box.containsKey(track.id)) {
      await box.delete(track.id);
    } else {
      await box.put(track.id, DateTime.now().millisecondsSinceEpoch);
    }
    _favoritesCache = _calculateFavorites();
    _currentMusic?.notifyFavoriteChanged();
    notifyListeners();
  }

  // Playlist management
  Future<void> createPlaylist(
    String name,
    List<Track> tracks, {
    int? icon,
    int? color,
  }) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      tracks: List.from(tracks),
      createdAt: DateTime.now(),
    );

    _playlists.add(playlist);
    _playlists.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    notifyListeners();
    await _playlistRepo.savePlaylist(playlist);
  }

  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.tracks.contains(track)) {
      playlist.tracks.add(track);
      notifyListeners();
      await _playlistRepo.savePlaylist(playlist);
      return true;
    }
    return false;
  }

  Future<void> removeTrackFromPlaylist(String playlistId, Track track) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    playlist.tracks.remove(track);
    notifyListeners();
    await _playlistRepo.savePlaylist(playlist);
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
    await _playlistRepo.deletePlaylist(playlistId);
  }

  Future<void> renamePlaylist(
    String playlistId,
    String newName, {
    int? icon,
    int? color,
  }) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(name: newName);
      notifyListeners();
      await _playlistRepo.savePlaylist(_playlists[index]);
    }
  }

  Future<void> reorderPlaylistTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final track = playlist.tracks.removeAt(oldIndex);
    playlist.tracks.insert(newIndex, track);
    notifyListeners();
    await _playlistRepo.savePlaylist(playlist);
  }

  // Search & filtering queries
  List<Track> searchTracks(String query) {
    if (query.isEmpty) return _tracks;
    final q = query.toLowerCase();
    return _tracks
        .where(
          (track) =>
              track.title.toLowerCase().contains(q) ||
              track.artist.toLowerCase().contains(q) ||
              track.album.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Album> searchAlbums(String query) {
    if (query.isEmpty) return _albums;
    final q = query.toLowerCase();
    return _albums
        .where(
          (album) =>
              album.title.toLowerCase().contains(q) ||
              album.artist.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Artist> searchArtists(String query) {
    if (query.isEmpty) return _artists;
    final q = query.toLowerCase();
    return _artists
        .where((artist) => artist.name.toLowerCase().contains(q))
        .toList();
  }

  List<Track> getTracksByAlbum(String albumTitle) {
    return _tracks.where((track) => track.album == albumTitle).toList();
  }

  List<Track> getTracksByArtist(String artistName) {
    return _tracks.where((track) => track.artist == artistName).toList();
  }

  List<Album> getAlbumsByArtist(String artistName) {
    return _albums.where((album) => album.artist == artistName).toList();
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    super.dispose();
  }
}
