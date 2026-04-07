import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import '../models/music/song.dart';
import '../models/music/album.dart';
import '../models/music/artist.dart';
import '../models/music/playlist.dart';
import '../core/hive_keys.dart';
import 'current_music_provider.dart';

class MusicProvider extends ChangeNotifier {
  List<Song> _songs = [];
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<Album> _albums = [];
  List<Artist> _artists = [];
  final List<Playlist> _playlists = [];

  bool _isLoading = false;
  final bool _hasScanned = false;
  String? _error;
  DateTime? _lastScanned;

  Playlist? _recentlyPlayedCache;
  Playlist? _topPlayedCache;
  Playlist? _favoritesCache;
  StreamSubscription<Song>? _playbackSubscription;

  // Getters
  List<Song> get songs => _songs;
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<Playlist> get playlists => _playlists;
  DateTime? get lastScanned => _lastScanned;

  /// Refreshes all cached playlists (recently played, top played, favorites).
  void refreshCaches() {
    _recentlyPlayedCache = _calculateRecentlyPlayed();
    _topPlayedCache = _calculateTopPlayed();
    _favoritesCache = _calculateFavorites();
    notifyListeners();
  }

  Playlist get recentlyPlayed =>
      _recentlyPlayedCache ??
      Playlist(
        id: 'recently_played',
        name: 'Recently Listened',
        songs: [],
        createdAt: DateTime.now(),
      );

  Playlist get topPlayed =>
      _topPlayedCache ??
      Playlist(
        id: 'top_played',
        name: 'Top Listened',
        songs: [],
        createdAt: DateTime.now(),
      );

  Playlist get favorites =>
      _favoritesCache ??
      Playlist(
        id: 'favorites',
        name: 'Favorites',
        songs: [],
        createdAt: DateTime.now(),
      );

  Playlist _calculateRecentlyPlayed() {
    if (!Hive.isBoxOpen(HiveKeys.playHistoryBox)) {
      return Playlist(
        id: 'recently_played',
        name: 'Recently Listened',
        songs: [],
        createdAt: DateTime.now(),
      );
    }
    final historyBox = Hive.box<int>(HiveKeys.playHistoryBox);
    final history = historyBox.toMap();
    final sortedEntries = history.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recentSongIds = sortedEntries.take(50).map((e) => e.key).toSet();
    final recentSongs = _songs
        .where((s) => recentSongIds.contains(s.id))
        .toList();

    recentSongs.sort((a, b) {
      final timeA = historyBox.get(a.id) ?? 0;
      final timeB = historyBox.get(b.id) ?? 0;
      return timeB.compareTo(timeA);
    });

    return Playlist(
      id: 'recently_played',
      name: 'Recently Listened',
      songs: recentSongs,
      createdAt: DateTime.now(),
    );
  }

  Playlist _calculateTopPlayed() {
    if (!Hive.isBoxOpen(HiveKeys.playCountsBox)) {
      return Playlist(
        id: 'top_played',
        name: 'Top Listened',
        songs: [],
        createdAt: DateTime.now(),
      );
    }
    final countsBox = Hive.box<int>(HiveKeys.playCountsBox);
    final counts = countsBox.toMap();
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topSongIds = sortedEntries.take(50).map((e) => e.key).toSet();
    final topSongs = _songs.where((s) => topSongIds.contains(s.id)).toList();

    topSongs.sort((a, b) {
      final countA = countsBox.get(a.id) ?? 0;
      final countB = countsBox.get(b.id) ?? 0;
      return countB.compareTo(countA);
    });

    return Playlist(
      id: 'top_played',
      name: 'Top Listened',
      songs: topSongs,
      createdAt: DateTime.now(),
    );
  }

  Playlist _calculateFavorites() {
    if (!Hive.isBoxOpen(HiveKeys.favoritesBox)) {
      return Playlist(
        id: 'favorites',
        name: 'Favorites',
        songs: [],
        createdAt: DateTime.now(),
      );
    }
    final favoritesBox = Hive.box<int>(HiveKeys.favoritesBox);
    final entries = favoritesBox.toMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final orderedIds = entries.map((e) => e.key as int).toList();
    final songMap = {for (final s in _songs) s.id: s};
    final favoriteSongs = orderedIds
        .where((id) => songMap.containsKey(id))
        .map((id) => songMap[id]!)
        .toList();

    return Playlist(
      id: 'favorites',
      name: 'Favorites',
      songs: favoriteSongs,
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
    await Hive.openBox<int>(HiveKeys.favoritesBox);
    await Hive.openBox<String>(HiveKeys.playlistsBox);
    await Hive.openBox<int>(HiveKeys.playHistoryBox);
    await Hive.openBox<int>(HiveKeys.playCountsBox);

    if (currentMusic != null) {
      _playbackSubscription?.cancel();
      _playbackSubscription = currentMusic.onSongPlayedStream.listen((_) {
        refreshCaches();
      });
    }

    await scanDevice(customFolders: customFolders);
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
        final audioStatus = await Permission.audio.request();
        final storageStatus = await Permission.storage.request();
        permissionStatus = audioStatus.isGranted || storageStatus.isGranted;
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

      _songs = validAudio.map((audio) {
        return Song(
          dateAdded: audio.dateAdded ?? 0,
          id: audio.id,
          title: audio.title,
          artist: audio.artist ?? '<Unknown>',
          album: audio.album ?? '<Unknown>',
          uri: audio.data,
          duration: audio.duration ?? 0,
          size: audio.size,
        );
      }).toList();

      _createAlbumsAndArtists();
      _loadPlaylists();

      _rebuildCaches();
      _lastScanned = DateTime.now();
    } catch (e) {
      _error = 'Failed to scan device: $e';
      debugPrint('Error querying MediaStore: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _rebuildCaches() {
    _recentlyPlayedCache = _calculateRecentlyPlayed();
    _topPlayedCache = _calculateTopPlayed();
    _favoritesCache = _calculateFavorites();
  }

  void _createAlbumsAndArtists() {
    final albumMap = <String, List<Song>>{};
    final artistMap = <String, List<Song>>{};

    for (final song in _songs) {
      // Group by album
      if (!albumMap.containsKey(song.album)) {
        albumMap[song.album] = [];
      }
      albumMap[song.album]!.add(song);

      // Group by artist
      if (!artistMap.containsKey(song.artist)) {
        artistMap[song.artist] = [];
      }
      artistMap[song.artist]!.add(song);
    }

    final Map<String, Album> createdAlbums = {};
    albumMap.forEach((albumTitle, songsInAlbum) {
      final album = Album(
        id: createdAlbums.length,
        title: albumTitle,
        artist: songsInAlbum.first.artist,
        numOfSongs: songsInAlbum.length,
      );
      createdAlbums[albumTitle] = album;
    });
    _albums = createdAlbums.values.toList();

    final Map<String, Artist> createdArtists = {};
    artistMap.forEach((artistName, songsByArtist) {
      final artist = Artist(
        id: createdArtists.length,
        name: artistName,
        numberOfAlbums: albumMap.values
            .where((songs) => songs.first.artist == artistName)
            .length,
        numberOfTracks: songsByArtist.length,
      );
      createdArtists[artistName] = artist;
    });
    _artists = createdArtists.values.toList();

    // Note: Song.albumObj and Song.artistObj were removed as they were not read by any UI component.
  }

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
          final songIdsList = data['songIds'] as List<dynamic>;
          final songIdsSet = songIdsList.map((e) => e as int).toSet();

          final playlistSongs = _songs
              .where((s) => songIdsSet.contains(s.id))
              .toList();

          _playlists.add(
            Playlist(
              id: id,
              name: name,
              songs: playlistSongs,
              createdAt: createdAt,
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
  /// Checks if a [song] is marked as favorite.
  bool isFavorite(Song song) {
    return Hive.box<int>(HiveKeys.favoritesBox).containsKey(song.id);
  }

  /// Toggles the favorite status for a [song].
  Future<void> toggleFavorite(Song song) async {
    final box = Hive.box<int>(HiveKeys.favoritesBox);

    if (box.containsKey(song.id)) {
      await box.delete(song.id);
    } else {
      await box.put(song.id, DateTime.now().millisecondsSinceEpoch);
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
      'songIds': p.songs.map((s) => s.id).toList(),
    };
    await box.put(p.id, jsonEncode(data));
  }

  // Playlist management
  Future<void> createPlaylist(String name, List<Song> songs) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: songs,
      createdAt: DateTime.now(),
    );

    _playlists.add(playlist);
    _playlists.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    notifyListeners();
    await _savePlaylist(playlist);
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.songs.contains(song)) {
      playlist.songs.add(song);
      notifyListeners();
      await _savePlaylist(playlist);
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, Song song) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    playlist.songs.remove(song);
    notifyListeners();
    await _savePlaylist(playlist);
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
    final box = Hive.box<String>(HiveKeys.playlistsBox);
    await box.delete(playlistId);
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(name: newName);
      notifyListeners();
      await _savePlaylist(_playlists[index]);
    }
  }

  Future<void> reorderPlaylistSongs(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final song = playlist.songs.removeAt(oldIndex);
    playlist.songs.insert(newIndex, song);
    notifyListeners();
    await _savePlaylist(playlist);
  }

  // Search functionality
  List<Song> searchSongs(String query) {
    if (query.isEmpty) return _songs;

    return _songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(query.toLowerCase()) ||
              song.artist.toLowerCase().contains(query.toLowerCase()) ||
              song.album.toLowerCase().contains(query.toLowerCase()),
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

  // Get songs by album
  List<Song> getSongsByAlbum(String albumTitle) {
    return _songs.where((song) => song.album == albumTitle).toList();
  }

  // Get songs by artist
  List<Song> getSongsByArtist(String artistName) {
    return _songs.where((song) => song.artist == artistName).toList();
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
