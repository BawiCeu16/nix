import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/album.dart';
import 'package:nix/models/music/artist.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/providers/current_music_provider.dart';

// ── Isolate data types ──

class _ParseInput {
  final List<Map<String, dynamic>> rawSongs;
  const _ParseInput(this.rawSongs);
}

class _ParseOutput {
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final Map<String, int> albumFirstTrackId;
  const _ParseOutput(
    this.tracks,
    this.albums,
    this.artists,
    this.albumFirstTrackId,
  );
}


/// Top-level function required by [compute] to run on a background isolate.
_ParseOutput _parseLibraryInIsolate(_ParseInput input) {
  final rawSongs = input.rawSongs;

  final tracks = rawSongs.map((raw) {
    return Track(
      dateAdded: raw['dateAdded'] as int? ?? 0,
      id: raw['id'] as int,
      title: raw['title'] as String,
      artist: raw['artist'] as String? ?? '<Unknown>',
      album: raw['album'] as String? ?? '<Unknown>',
      uri: raw['uri'] as String,
      duration: raw['duration'] as int? ?? 0,
      size: raw['size'] as int? ?? 0,
    );
  }).toList();

  final albumMap = <String, List<Track>>{};
  final artistMap = <String, List<Track>>{};
  for (final track in tracks) {
    albumMap.putIfAbsent(track.album, () => []).add(track);
    artistMap.putIfAbsent(track.artist, () => []).add(track);
  }

  var albumIdx = 0;
  final albums = albumMap.entries.map((entry) {
    return Album(
      id: albumIdx++,
      title: entry.key,
      artist: entry.value.first.artist,
      numOfSongs: entry.value.length,
    );
  }).toList();

  var artistIdx = 0;
  final artists = artistMap.entries.map((entry) {
    return Artist(
      id: artistIdx++,
      name: entry.key,
      numberOfAlbums: albumMap.values
          .where((tracks) => tracks.first.artist == entry.key)
          .length,
      numberOfTracks: entry.value.length,
    );
  }).toList();

  final albumFirstTrackId = <String, int>{};
  for (final track in tracks) {
    albumFirstTrackId.putIfAbsent(track.album, () => track.id);
  }

  return _ParseOutput(tracks, albums, artists, albumFirstTrackId);
}


class MusicProvider extends ChangeNotifier {
  List<Track> _tracks = [];
  final OnAudioQuery _audioQuery = OnAudioQuery();
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


  /// Refreshes all cached playlists (recently played, top played, favorites).
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

  bool get isLoading => _isLoading;
  bool get hasScanned => _hasScanned;
  String? get error => _error;

  /// Initializes storage and begins background device scan.
  Future<void> init({
    List<String>? customFolders,
    CurrentMusicProvider? currentMusic,
  }) async {
    // Parallelize Hive box openings
    await Future.wait([
      Hive.openBox<int>(HiveKeys.favoritesBox),
      Hive.openBox<String>(HiveKeys.playlistsBox),
      Hive.openBox<int>(HiveKeys.playHistoryBox),
      Hive.openBox<int>(HiveKeys.playCountsBox),
    ]);


    if (currentMusic != null) {
      _currentMusic = currentMusic;
      _playbackSubscription?.cancel();
      _playbackSubscription = currentMusic.onTrackPlayedStream.listen((_) {
        refreshCaches();
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
      if (Hive.isBoxOpen(HiveKeys.playlistsBox)) {
        await Hive.box<String>(HiveKeys.playlistsBox).clear();
      }

      // Re-scan library
      _isLoading = false;
      await scanDevice();
    } catch (e) {
      debugPrint('Error resetting library: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Scans the device for valid audio files and builds the library state.
  Future<void> scanDevice({List<String>? customFolders}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool permissionStatus = false;
      if (Platform.isIOS) {
        permissionStatus = await _audioQuery.permissionsStatus();
        if (!permissionStatus) {
          permissionStatus = await _audioQuery.permissionsRequest();
        }
      } else {
        // Parallelize permission requests
        final results = await Future.wait([
          Permission.audio.request(),
          Permission.storage.request(),
        ]);
        permissionStatus = results.any((status) => status.isGranted);
      }


      if (!permissionStatus) {
        _error = 'Storage permission not granted. Cannot scan music.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final audioList = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // Read min duration from settings
      final settingsBox = Hive.box(HiveKeys.settingsBox);
      final int minDurationSeconds =
          settingsBox.get(HiveKeys.minDuration, defaultValue: 0) ?? 0;
      final int minDurationMs = minDurationSeconds * 1000;

      final validAudio = audioList.where((item) {
        final bool isAcceptedType =
            item.isMusic == true || item.isPodcast == true;
        final bool isLongEnough = (item.duration ?? 0) >= minDurationMs;
        return isAcceptedType && isLongEnough;
      }).toList();

      // Opt. #7: Run the CPU-intensive parsing on a background isolate via
      // compute(), preventing UI-thread jank on startup with large libraries.
      final rawSongs = validAudio.map((audio) => <String, dynamic>{
        'dateAdded': audio.dateAdded ?? 0,
        'id': audio.id,
        'title': audio.title,
        'artist': audio.artist,
        'album': audio.album,
        'uri': audio.data,
        'duration': audio.duration ?? 0,
        'size': audio.size,
      }).toList();

      final parsed = await compute(
        _parseLibraryInIsolate,
        _ParseInput(rawSongs),
      );

      _tracks = parsed.tracks;
      _albums = parsed.albums;
      _artists = parsed.artists;
      _albumFirstTrackId = parsed.albumFirstTrackId;


      // Parallelize playlist loading and cache rebuilding
      await Future.wait([
        Future(() => _loadPlaylists()),
        _rebuildCaches(),
      ]);
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


  // _createAlbumsAndArtists() is now handled in the background isolate.

  void _loadPlaylists() {
    _playlists.clear();
    final box = Hive.box<String>(HiveKeys.playlistsBox);
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final id = data['id'] as String;
          final name = data['name'] as String;
          final createdAt = DateTime.fromMillisecondsSinceEpoch(
            data['createdAt'] as int,
          );
          final trackIdsList = data['trackIds'] as List<dynamic>;
          final trackIds = trackIdsList.map((e) => e as int).toList();

          final trackMap = {for (final t in _tracks) t.id: t};
          final playlistTracks = trackIds
              .where((id) => trackMap.containsKey(id))
              .map((id) => trackMap[id]!)
              .toList();

          _playlists.add(
            Playlist(
              id: id,
              name: name,
              tracks: playlistTracks,
              createdAt: createdAt,
              iconCodePoint: data['iconCodePoint'] as int?,
              colorValue: data['colorValue'] as int?,
            ),
          );
        } catch (e) {
          debugPrint('Failed to load playlist $key: $e');
        }
      }
    }
    _playlists.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
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
    notifyListeners();
  }


  Future<void> _savePlaylist(Playlist p) async {
    final box = Hive.box<String>(HiveKeys.playlistsBox);
    final data = {
      'id': p.id,
      'name': p.name,
      'createdAt': p.createdAt.millisecondsSinceEpoch,
      'trackIds': p.tracks.map((s) => s.id).toList(),
      'iconCodePoint': p.iconCodePoint,
      'colorValue': p.colorValue,
    };
    await box.put(p.id, jsonEncode(data));
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
      iconCodePoint: icon,
      colorValue: color,
    );

    _playlists.add(playlist);
    _playlists.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    notifyListeners();
    await _savePlaylist(playlist);
  }

  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.tracks.contains(track)) {
      playlist.tracks.add(track);
      notifyListeners();
      await _savePlaylist(playlist);
      return true;
    }
    return false;
  }

  Future<void> removeTrackFromPlaylist(String playlistId, Track track) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    playlist.tracks.remove(track);
    notifyListeners();
    await _savePlaylist(playlist);
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
    final box = Hive.box<String>(HiveKeys.playlistsBox);
    await box.delete(playlistId);
  }

  Future<void> renamePlaylist(
    String playlistId,
    String newName, {
    int? icon,
    int? color,
  }) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(
        name: newName,
        iconCodePoint: icon,
        colorValue: color,
        clearIcon: icon == null,
        clearColor: color == null,
      );
      notifyListeners();
      await _savePlaylist(_playlists[index]);
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
    await _savePlaylist(playlist);
  }

  // Search functionality
  List<Track> searchTracks(String query) {
    if (query.isEmpty) return _tracks;

    return _tracks
        .where(
          (track) =>
              track.title.toLowerCase().contains(query.toLowerCase()) ||
              track.artist.toLowerCase().contains(query.toLowerCase()) ||
              track.album.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  List<Album> searchAlbums(String query) {
    if (query.isEmpty) return _albums;

    return _albums
        .where(
          (album) =>
              album.title.toLowerCase().contains(query.toLowerCase()) ||
              album.artist.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  List<Artist> searchArtists(String query) {
    if (query.isEmpty) return _artists;

    return _artists
        .where(
          (artist) => artist.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Get tracks by album
  List<Track> getTracksByAlbum(String albumTitle) {
    return _tracks.where((track) => track.album == albumTitle).toList();
  }

  // Get tracks by artist
  List<Track> getTracksByArtist(String artistName) {
    return _tracks.where((track) => track.artist == artistName).toList();
  }

  // Get albums by artist
  List<Album> getAlbumsByArtist(String artistName) {
    return _albums.where((album) => album.artist == artistName).toList();
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    super.dispose();
  }
}
