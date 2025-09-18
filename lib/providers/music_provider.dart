// lib/providers/music_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortOption { titleAsc, titleDesc, artistAsc, durationAsc }

enum RepeatMode { off, one, all }

class MusicProvider with ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _songs = [];
  List<int> _favoriteSongIds = [];
  SongModel? _currentSong;
  Uint8List? _cachedArtworkData;
  bool _isMiniPlayerExpanded = false;
  bool _isMiniPlayerFullyExpanded = false;
  bool _isShuffleOn = false;
  RepeatMode _repeatMode = RepeatMode.off;
  String _searchQuery = "";
  String _connectedDeviceName = "Unknown";
  SortOption _sortOption = SortOption.titleAsc;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  static const MethodChannel _channel = MethodChannel('audio_output');
  ConcatenatingAudioSource? _playlist;
  Map<String, List<int>> _playlists =
      {}; // key: playlist name, value: list of song IDs
  String? _currentPlaylist; // Active playlist name

  static const _notifChannel = MethodChannel("nix/notifications");

  List<Map<String, dynamic>> _lyrics = [];
  int _currentLyricIndex = 0;

  // ---------- Recently / Most listened state ----------
  final Map<int, int> _playCounts = {};
  final List<Map<String, dynamic>> _recentPlays = [];
  static const int _recentPlaysCap = 200;

  // New: current audio queue that mirrors the player's sequence
  List<SongModel> _currentAudioQueue = [];

  // NEW: system favorites playlist id (Android). null if not created / not available.
  int? _favoriteSystemPlaylistId;

  // NEW: user setting: whether to auto-sync favorites to system playlist
  bool _favSystemSyncEnabled = false;

  // ✅ Getters
  List<SongModel> get songs => _songs;
  List<int> get favoriteSongIds => _favoriteSongIds;
  SongModel? get currentSong => _currentSong;
  Uint8List? get cachedArtworkData => _cachedArtworkData;
  bool get isPlaying => _audioPlayer.playing;
  bool get isMiniPlayerExpanded => _isMiniPlayerExpanded;
  bool get isMiniPlayerFullyExpanded => _isMiniPlayerFullyExpanded;
  bool get isShuffleOn => _isShuffleOn;
  RepeatMode get repeatMode => _repeatMode;
  String get searchQuery => _searchQuery;
  String get connectedDeviceName => _connectedDeviceName;
  SortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  AudioPlayer get audioPlayer => _audioPlayer;

  Map<String, List<int>> get playlists => _playlists;
  String? get currentPlaylist => _currentPlaylist;

  List<Map<String, dynamic>> get lyrics => _lyrics;
  int get currentLyricIndex => _currentLyricIndex;

  List<SongModel> get currentAudioQueue =>
      List.unmodifiable(_currentAudioQueue);

  int? get favoriteSystemPlaylistId => _favoriteSystemPlaylistId;
  bool get favSystemSyncEnabled => _favSystemSyncEnabled;

  // ---------- Constructor ----------
  MusicProvider() {
    loadFavorites();
    _loadPlaylists();
    _loadPlayStats();
    _listenToPlayerStreams();
    checkAndLoadSongs();
    _initFavoriteSystemPlaylist();
  }

  // ---------- Songs loading ----------
  Future<void> checkAndLoadSongs() async {
    final hasPermission = await _audioQuery.permissionsStatus();
    if (hasPermission) {
      await _loadSongs();
    }
  }

  Future<void> requestAndLoadSongs() async {
    final granted = await _audioQuery.permissionsRequest();
    if (granted) {
      await _loadSongs();
    }
  }

  Future<void> _loadSongs() async {
    _isLoading = true;
    notifyListeners();
    _songs = await _audioQuery.querySongs();
    _applySort();
    await _buildPlaylist(); // build playlist from loaded songs
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshSongs() async {
    _songs = await _audioQuery.querySongs();
    _applySort();
    await _rebuildPlaylistPreservePlayback();
    notifyListeners();
  }

  // ---------- Player streams (no auto-counting) ----------
  void _listenToPlayerStreams() {
    _audioPlayer.positionStream.listen((pos) {
      _currentPosition = pos;
      _syncLyrics(pos);
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      _totalDuration = dur ?? Duration.zero;
      notifyListeners();
    });

    // update _currentSong when index changes
    _audioPlayer.currentIndexStream.listen((index) {
      try {
        final seq = _audioPlayer.sequence;
        if (seq != null && seq.isNotEmpty) {
          final idx = index ?? _audioPlayer.currentIndex ?? 0;
          if (idx >= 0 && idx < seq.length) {
            final tag = seq[idx].tag;
            if (tag is MediaItem) {
              final id = int.tryParse(tag.id);
              if (id != null) {
                final songIndex = _songs.indexWhere((s) => s.id == id);
                if (songIndex != -1) {
                  _currentSong = _songs[songIndex];
                } else {
                  final qIndex = _currentAudioQueue.indexWhere(
                    (s) => s.id == id,
                  );
                  _currentSong = qIndex != -1
                      ? _currentAudioQueue[qIndex]
                      : null;
                }
                _cachedArtworkData = null;
                if (_currentSong != null) {
                  fetchLyricsFromLrcLib(
                    _currentSong!.title,
                    _currentSong!.artist ?? "Unknown",
                  );
                }
              } else {
                _currentSong = null;
              }
            } else {
              _currentSong = null;
            }
          } else {
            _currentSong = null;
          }
        } else {
          final idx = index ?? -1;
          if (idx >= 0 && idx < _currentAudioQueue.length) {
            _currentSong = _currentAudioQueue[idx];
          } else if (idx >= 0 && idx < _songs.length) {
            _currentSong = _songs[idx];
          } else {
            _currentSong = null;
          }
        }
      } catch (e) {
        debugPrint("Error resolving current song from sequence: $e");
        _currentSong = null;
      }
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      notifyListeners();
    });
  }

  // ---------- Sorting ----------
  Future<void> setSortOption(SortOption option) async {
    _sortOption = option;
    _applySort();
    await _rebuildPlaylistPreservePlayback();
    notifyListeners();
  }

  void _applySort() {
    switch (_sortOption) {
      case SortOption.titleAsc:
        _songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.titleDesc:
        _songs.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortOption.artistAsc:
        _songs.sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
        break;
      case SortOption.durationAsc:
        _songs.sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0));
        break;
    }
  }

  Future<void> _rebuildPlaylistPreservePlayback() async {
    try {
      final wasPlaying = _audioPlayer.playing;
      final currentPosition = _audioPlayer.position;
      final currentSongId = _currentSong?.id;

      _currentAudioQueue = List.from(_songs);

      _playlist = ConcatenatingAudioSource(
        children: _currentAudioQueue.map((song) {
          final artworkUri = song.albumId != null
              ? Uri.parse(
                  "content://media/external/audio/albumart/${song.albumId}",
                )
              : Uri.parse("https://via.placeholder.com/150");

          return AudioSource.uri(
            Uri.parse(song.uri!),
            tag: MediaItem(
              id: song.id.toString(),
              album: song.album ?? 'Unknown Album',
              title: song.title,
              artist: song.artist ?? 'Unknown Artist',
              artUri: artworkUri,
            ),
          );
        }).toList(),
      );

      int initialIndex = 0;
      if (currentSongId != null) {
        final newIndex = _currentAudioQueue.indexWhere(
          (s) => s.id == currentSongId,
        );
        if (newIndex != -1) initialIndex = newIndex;
      }

      await _audioPlayer.setAudioSource(_playlist!, initialIndex: initialIndex);
      await _audioPlayer.seek(currentPosition, index: initialIndex);

      if (wasPlaying) {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("Error rebuilding playlist: $e");
    }
  }

  // ---------- Favorites (in-app + optional Android system playlist) ----------
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteSongIds =
        prefs.getStringList('favorites')?.map(int.parse).toList() ?? [];

    // restore sync flag
    _favSystemSyncEnabled = prefs.getBool('fav_sync_enabled') ?? false;

    // try to read saved system playlist id
    final favSysId = prefs.getInt('fav_system_playlist_id');
    if (favSysId != null) {
      _favoriteSystemPlaylistId = favSysId;
      if (Platform.isAndroid) {
        try {
          final systemSongs = await _loadSongIdsFromSystemPlaylist(
            _favoriteSystemPlaylistId!,
          );
          final merged = <int>{..._favoriteSongIds, ...systemSongs};
          _favoriteSongIds = merged.toList();
        } catch (e) {
          debugPrint("Error syncing favorites from system playlist: $e");
        }
      }
    }

    notifyListeners();
  }

  Future<void> toggleFavorite(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    final already = _favoriteSongIds.contains(songId);

    if (already) {
      _favoriteSongIds.remove(songId);
    } else {
      _favoriteSongIds.add(songId);
    }

    await prefs.setStringList(
      'favorites',
      _favoriteSongIds.map((id) => id.toString()).toList(),
    );

    if (Platform.isAndroid) {
      try {
        if (_favSystemSyncEnabled) {
          await _ensureFavoriteSystemPlaylistExists();
          if (_favoriteSystemPlaylistId != null) {
            if (already) {
              await removeSongFromSystemPlaylist(
                _favoriteSystemPlaylistId!,
                songId,
              );
            } else {
              await addSongToSystemPlaylist(_favoriteSystemPlaylistId!, songId);
            }
          }
        } else {
          // If sync is disabled but we still have a recorded system playlist id, do nothing.
        }
      } catch (e) {
        debugPrint("Error syncing favorite to system playlist: $e");
      }
    }

    notifyListeners();
  }

  bool isFavorite(int songId) => _favoriteSongIds.contains(songId);

  Future<List<int>> _loadSongIdsFromSystemPlaylist(int playlistId) async {
    try {
      final songs = await _audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST,
        playlistId,
      );
      return songs.map((s) => s.id).toList();
    } catch (e) {
      debugPrint("Error loading songs from system playlist: $e");
      return [];
    }
  }

  Future<void> _ensureFavoriteSystemPlaylistExists() async {
    if (!Platform.isAndroid) return;
    if (_favoriteSystemPlaylistId != null) return;

    final prefs = await SharedPreferences.getInstance();
    const favName = "Favorites";

    try {
      final systemPlaylists = await _audioQuery.queryPlaylists();
      final idx = systemPlaylists.indexWhere((p) => p.playlist == favName);
      if (idx != -1) {
        _favoriteSystemPlaylistId = systemPlaylists[idx].id;
        await prefs.setInt(
          'fav_system_playlist_id',
          _favoriteSystemPlaylistId!,
        );
        return;
      }
    } catch (e) {
      debugPrint("Error querying system playlists: $e");
    }

    try {
      final hasPerm = await _audioQuery.permissionsStatus();
      if (!hasPerm) {
        final granted = await _audioQuery.permissionsRequest();
        if (!granted) return;
      }

      final created = await _audioQuery.createPlaylist(favName);
      if (created) {
        final systemPlaylists = await _audioQuery.queryPlaylists();
        final idx = systemPlaylists.indexWhere((p) => p.playlist == favName);
        if (idx != -1) {
          _favoriteSystemPlaylistId = systemPlaylists[idx].id;
          await prefs.setInt(
            'fav_system_playlist_id',
            _favoriteSystemPlaylistId!,
          );
        }
      }
    } catch (e) {
      debugPrint("Error creating system favorites playlist: $e");
    }
  }

  Future<void> _initFavoriteSystemPlaylist() async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final favSysId = prefs.getInt('fav_system_playlist_id');
      if (favSysId != null) {
        _favoriteSystemPlaylistId = favSysId;
        try {
          final sysIds = await _loadSongIdsFromSystemPlaylist(favSysId);
          final merged = <int>{..._favoriteSongIds, ...sysIds};
          _favoriteSongIds = merged.toList();
          notifyListeners();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Error init favorite system playlist: $e");
    }
  }

  Future<void> setFavoriteSystemSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _favSystemSyncEnabled = enabled;
    await prefs.setBool('fav_sync_enabled', enabled);

    if (enabled && Platform.isAndroid) {
      try {
        await _ensureFavoriteSystemPlaylistExists();
        if (_favoriteSystemPlaylistId != null) {
          await exportFavoritesToSystem();
        }
      } catch (e) {
        debugPrint("Error enabling favorite-system sync: $e");
      }
    }

    notifyListeners();
  }

  Future<void> exportFavoritesToSystem() async {
    if (!Platform.isAndroid) return;

    try {
      await _ensureFavoriteSystemPlaylistExists();
      if (_favoriteSystemPlaylistId == null) return;

      final existing = await _loadSongIdsFromSystemPlaylist(
        _favoriteSystemPlaylistId!,
      );
      final toAdd = _favoriteSongIds
          .where((id) => !existing.contains(id))
          .toList();

      for (final id in toAdd) {
        try {
          await addSongToSystemPlaylist(_favoriteSystemPlaylistId!, id);
        } catch (e) {
          debugPrint("Failed adding $id to system favorites: $e");
        }
      }
    } catch (e) {
      debugPrint("exportFavoritesToSystem error: $e");
    }
  }

  // ---------- Search ----------
  List<SongModel> get filteredSongs {
    if (_searchQuery.isEmpty) return _songs;
    return _songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (song.artist ?? '').toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = "";
    notifyListeners();
  }

  // ---------- Upcoming / mini player ----------
  List<SongModel> get upcomingSongs {
    if (_currentAudioQueue.isEmpty) return [];
    final idx =
        _audioPlayer.currentIndex ??
        (_currentSong != null ? _currentAudioQueue.indexOf(_currentSong!) : -1);
    if (idx == -1 || idx >= _currentAudioQueue.length - 1) return [];
    return _currentAudioQueue.sublist(idx + 1);
  }

  SongModel? get nextSongIfEndingSoon {
    if (_currentSong == null || _totalDuration == Duration.zero) return null;
    final remaining = _totalDuration - _currentPosition;
    if (remaining.inSeconds <= 20) {
      final index =
          _audioPlayer.currentIndex ??
          (_currentSong != null
              ? _currentAudioQueue.indexOf(_currentSong!)
              : -1);
      if (index != -1 && index < _currentAudioQueue.length - 1) {
        return _currentAudioQueue[index + 1];
      }
    }
    return null;
  }

  void toggleMiniPlayer() {
    _isMiniPlayerExpanded = !_isMiniPlayerExpanded;
    notifyListeners();
  }

  void setMiniPlayerFullExpansion(bool isFull) {
    if (_isMiniPlayerFullyExpanded != isFull) {
      _isMiniPlayerFullyExpanded = isFull;
      notifyListeners();
    }
  }

  // ---------- Artwork ----------
  Future<Uint8List?> fetchArtwork(int songId) async {
    _cachedArtworkData = await _audioQuery.queryArtwork(
      songId,
      ArtworkType.AUDIO,
      size: 700,
    );
    notifyListeners();
    return _cachedArtworkData;
  }

  // ---------- Playback controls ----------
  Future<void> playSong(SongModel song) async {
    final index = _songs.indexOf(song);
    if (index == -1) return;

    try {
      if (_playlist == null) {
        await _buildPlaylist();
      }

      await _audioPlayer.setAudioSource(_playlist!, initialIndex: index);
      await _audioPlayer.play();

      _currentSong = song;
      _cachedArtworkData = null;
      notifyListeners();
      _updateNotification(song.title, song.artist ?? "Unknown Artist", true);
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  Future<void> recordClickAndPlay(SongModel song) async {
    recordSongClick(song.id);
    await playSong(song);
  }

  void recordSongClick(int songId) {
    _recordPlay(songId);
  }

  Future<void> playNext() async {
    try {
      if (_audioPlayer.hasNext) {
        await _audioPlayer.seekToNext();
      } else {
        await _audioPlayer.seek(Duration.zero, index: 0);
      }

      await _audioPlayer.play();

      final idx = _audioPlayer.currentIndex;
      SongModel? s;
      if (idx != null && idx >= 0) {
        if (idx < _currentAudioQueue.length)
          s = _currentAudioQueue[idx];
        else if (idx < _songs.length)
          s = _songs[idx];
      }
      if (s != null) {
        _recordPlay(s.id);
      }
    } catch (e) {
      debugPrint("Error in playNext: $e");
    }
  }

  Future<void> playPrevious() async {
    try {
      if (_audioPlayer.hasPrevious) {
        await _audioPlayer.seekToPrevious();
      } else {
        final lastIndex = _audioPlayer.sequence?.length ?? 0;
        if (lastIndex > 0) {
          await _audioPlayer.seek(Duration.zero, index: lastIndex - 1);
        }
      }

      await _audioPlayer.play();

      final idx = _audioPlayer.currentIndex;
      SongModel? s;
      if (idx != null && idx >= 0) {
        if (idx < _currentAudioQueue.length)
          s = _currentAudioQueue[idx];
        else if (idx < _songs.length)
          s = _songs[idx];
      }
      if (s != null) {
        _recordPlay(s.id);
      }
    } catch (e) {
      debugPrint("Error in playPrevious: $e");
    }
  }

  void pause() => _audioPlayer.pause();
  void resume() => _audioPlayer.play();
  void stop() => _audioPlayer.stop();

  Future<void> _buildPlaylist() async {
    _currentAudioQueue = List.from(_songs);
    _playlist = ConcatenatingAudioSource(
      children: _currentAudioQueue.map((song) {
        final artworkUri = song.albumId != null
            ? Uri.parse(
                "content://media/external/audio/albumart/${song.albumId}",
              )
            : Uri.parse("https://via.placeholder.com/150");

        return AudioSource.uri(
          Uri.parse(song.uri!),
          tag: MediaItem(
            id: song.id.toString(),
            album: song.album ?? 'Unknown Album',
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            artUri: artworkUri,
          ),
        );
      }).toList(),
    );
  }

  void toggleShuffle() {
    _isShuffleOn = !_isShuffleOn;
    _audioPlayer.setShuffleModeEnabled(_isShuffleOn);
    notifyListeners();
  }

  void cycleRepeatMode() {
    if (_repeatMode == RepeatMode.off) {
      _repeatMode = RepeatMode.one;
      _audioPlayer.setLoopMode(LoopMode.one);
    } else if (_repeatMode == RepeatMode.one) {
      _repeatMode = RepeatMode.all;
      _audioPlayer.setLoopMode(LoopMode.all);
    } else {
      _repeatMode = RepeatMode.off;
      _audioPlayer.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  Future<void> clearCurrentSong() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []));
      _playlist = null;
      _currentSong = null;
      _cachedArtworkData = null;
      _currentAudioQueue = [];
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing current song: $e");
    }
  }

  Stream<Duration> get throttledPositionStream => _audioPlayer.positionStream
      .throttleTime(const Duration(milliseconds: 500));

  get currentLine => null;
  void seek(Duration position) => _audioPlayer.seek(position);

  // ---------- Playlists (app-level persisted in SharedPreferences) ----------
  Future<void> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('playlists') ?? '{}';
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    _playlists = decoded.map(
      (key, value) => MapEntry(key, List<int>.from(value)),
    );
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedPlaylists = _playlists.map(
      (key, value) => MapEntry(key, value.map((id) => id.toString()).toList()),
    );
    await prefs.setString('playlists', jsonEncode(encodedPlaylists));
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('playlists');
    if (data != null) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      _playlists = decoded.map(
        (key, value) =>
            MapEntry(key, (value as List).map((id) => int.parse(id)).toList()),
      );
      notifyListeners();
    }
  }

  Future<void> createPlaylist(String name) async {
    if (!_playlists.containsKey(name)) {
      _playlists[name] = [];
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> addSongToPlaylist(String playlistName, int songId) async {
    if (!_playlists.containsKey(playlistName)) {
      _playlists[playlistName] = [];
    }
    if (!_playlists[playlistName]!.contains(songId)) {
      _playlists[playlistName]!.add(songId);
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> removeSongFromPlaylist(String playlistName, int songId) async {
    _playlists[playlistName]?.remove(songId);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> playPlaylist(String playlistName) async {
    if (!_playlists.containsKey(playlistName)) return;

    _currentPlaylist = playlistName;

    final songIds = _playlists[playlistName]!;
    final playlistSongs = _songs
        .where((song) => songIds.contains(song.id))
        .toList();

    if (playlistSongs.isEmpty) return;

    _currentAudioQueue = List.from(playlistSongs);

    final children = <AudioSource>[];
    for (var song in _currentAudioQueue) {
      final artworkUri = song.albumId != null
          ? Uri.parse("content://media/external/audio/albumart/${song.albumId}")
          : Uri.parse("https://via.placeholder.com/150");

      children.add(
        AudioSource.uri(
          Uri.parse(song.uri!),
          tag: MediaItem(
            id: song.id.toString(),
            album: song.album ?? 'Unknown Album',
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            artUri: artworkUri,
          ),
        ),
      );
    }

    _playlist = ConcatenatingAudioSource(children: children);

    await _audioPlayer.setAudioSource(_playlist!);
    await _audioPlayer.play();

    _currentSong = _currentAudioQueue.first;
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistName) async {
    _playlists.remove(playlistName);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String oldName, String newName) async {
    if (_playlists.containsKey(newName)) return;
    final songs = _playlists.remove(oldName);
    if (songs != null) {
      _playlists[newName] = songs;
      await _savePlaylists();
      notifyListeners();
    }
  }

  // ---------- System (device) playlists integration for Android ----------
  List<PlaylistModel> _systemPlaylists = [];
  List<PlaylistModel> get systemPlaylists =>
      List.unmodifiable(_systemPlaylists);

  Future<bool> createSystemPlaylist(
    String name, {
    String? author,
    String? description,
  }) async {
    final hasPermission = await _audioQuery.permissionsStatus();
    if (!hasPermission) {
      final granted = await _audioQuery.permissionsRequest();
      if (!granted) return false;
    }

    try {
      final created = await _audioQuery.createPlaylist(name);
      if (created) {
        await loadSystemPlaylists();
      }
      return created;
    } catch (e) {
      debugPrint('createSystemPlaylist error: $e');
      return false;
    }
  }

  Future<bool> addSongToSystemPlaylist(int playlistId, int songId) async {
    final hasPermission = await _audioQuery.permissionsStatus();
    if (!hasPermission) {
      final granted = await _audioQuery.permissionsRequest();
      if (!granted) return false;
    }

    try {
      final added = await _audioQuery.addToPlaylist(playlistId, songId);
      if (added) {
        await loadSystemPlaylists();
      }
      return added;
    } catch (e) {
      debugPrint('addSongToSystemPlaylist error: $e');
      return false;
    }
  }

  Future<bool> removeSongFromSystemPlaylist(int playlistId, int songId) async {
    final hasPermission = await _audioQuery.permissionsStatus();
    if (!hasPermission) {
      final granted = await _audioQuery.permissionsRequest();
      if (!granted) return false;
    }

    try {
      final removed = await _audioQuery.removeFromPlaylist(playlistId, songId);
      if (removed) {
        await loadSystemPlaylists();
      }
      return removed;
    } catch (e) {
      debugPrint('removeSongFromSystemPlaylist error: $e');
      return false;
    }
  }

  Future<bool> deleteSystemPlaylist(int playlistId) async {
    final hasPermission = await _audioQuery.permissionsStatus();
    if (!hasPermission) {
      final granted = await _audioQuery.permissionsRequest();
      if (!granted) return false;
    }

    try {
      final deleted = await _audioQuery.removePlaylist(playlistId);
      if (deleted) await loadSystemPlaylists();
      return deleted;
    } catch (e) {
      debugPrint('deleteSystemPlaylist error: $e');
      return false;
    }
  }

  Future<void> loadSystemPlaylists() async {
    final hasPermission = await _audioQuery.permissionsStatus();
    if (!hasPermission) {
      final granted = await _audioQuery.permissionsRequest();
      if (!granted) return;
    }
    try {
      final list = await _audioQuery.queryPlaylists();
      _systemPlaylists = list;
      notifyListeners();
    } catch (e) {
      debugPrint('loadSystemPlaylists error: $e');
    }
  }

  Future<List<SongModel>> loadSongsFromSystemPlaylist(int playlistId) async {
    final hasPermission = await _audioQuery.permissionsStatus();
    if (!hasPermission) {
      final granted = await _audioQuery.permissionsRequest();
      if (!granted) return [];
    }
    try {
      final songsInPlaylist = await _audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST,
        playlistId,
      );
      return songsInPlaylist;
    } catch (e) {
      debugPrint('loadSongsFromSystemPlaylist error: $e');
      return [];
    }
  }

  Future<void> playSystemPlaylist(int playlistId) async {
    final songs = await loadSongsFromSystemPlaylist(playlistId);
    if (songs.isEmpty) return;

    _currentAudioQueue = List.from(songs);

    final children = songs.map((song) {
      final artworkUri = song.albumId != null
          ? Uri.parse("content://media/external/audio/albumart/${song.albumId}")
          : Uri.parse("https://via.placeholder.com/150");

      return AudioSource.uri(
        Uri.parse(song.uri!),
        tag: MediaItem(
          id: song.id.toString(),
          album: song.album ?? 'Unknown Album',
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          artUri: artworkUri,
        ),
      );
    }).toList();

    _playlist = ConcatenatingAudioSource(children: children);
    try {
      await _audioPlayer.setAudioSource(_playlist!, initialIndex: 0);
      await _audioPlayer.play();

      final idx = _systemPlaylists.indexWhere((p) => p.id == playlistId);
      if (idx != -1) {
        _currentPlaylist = _systemPlaylists[idx].playlist;
      } else {
        _currentPlaylist = null;
      }

      _currentSong = songs.first;
      notifyListeners();
    } catch (e) {
      debugPrint('playSystemPlaylist error: $e');
    }
  }

  // ---------- Sharing ----------
  Future<void> shareCurrentSong() async {
    if (_currentSong?.data != null) {
      try {
        await Share.shareXFiles([
          XFile(_currentSong!.data),
        ], text: 'Listen to "${_currentSong!.title}"');
      } catch (e) {
        debugPrint("Error sharing file: $e");
      }
    }
  }

  Future<void> _updateNotification(
    String title,
    String artist,
    bool isPlaying,
  ) async {
    try {
      await _notifChannel.invokeMethod("updateNotification", {
        "title": title,
        "artist": artist,
        "isPlaying": isPlaying,
      });
    } catch (e) {
      debugPrint("Error updating notification: $e");
    }
  }

  Future<void> _hideNotification() async {
    try {
      await _notifChannel.invokeMethod("hideNotification");
    } catch (e) {
      debugPrint("Error hiding notification: $e");
    }
  }

  // ---------- Lyrics ----------
  Future<void> fetchLyricsFromLrcLib(String title, String artist) async {
    try {
      final url =
          "https://lrclib.net/api/get?track_name=${Uri.encodeComponent(title)}&artist_name=${Uri.encodeComponent(artist)}";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['syncedLyrics'] != null) {
          _lyrics = _parseLRC(data['syncedLyrics']);
        } else if (data['plainLyrics'] != null) {
          _lyrics = _plainToLyrics(data['plainLyrics']);
        } else {
          _lyrics = [
            {"time": 0, "line": "No lyrics found"},
          ];
        }
        _currentLyricIndex = 0;
        notifyListeners();
        _audioPlayer.positionStream.listen(_syncLyrics);
      } else {
        _lyrics = [
          {"time": 0, "line": "Lyrics not available"},
        ];
        notifyListeners();
      }
    } catch (e) {
      _lyrics = [
        {"time": 0, "line": "Error loading lyrics"},
      ];
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _parseLRC(String lrc) {
    final regex = RegExp(r"\[(\d+):(\d+)\.(\d+)\](.*)");
    return lrc.split("\n").map((line) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millis = int.parse(match.group(3)!);
        final time = (minutes * 60000) + (seconds * 1000) + millis * 10;
        return {"time": time, "line": match.group(4)!.trim()};
      }
      return {"time": 0, "line": line.trim()};
    }).toList();
  }

  List<Map<String, dynamic>> _plainToLyrics(String text) {
    return text.split("\n").map((line) => {"time": 0, "line": line}).toList();
  }

  void _syncLyrics(Duration position) {
    for (int i = 0; i < _lyrics.length; i++) {
      if (position.inMilliseconds >= _lyrics[i]['time']) {
        _currentLyricIndex = i;
      }
    }
    notifyListeners();
  }

  // ---------- Recently & Most listened (persistence + helpers) ----------
  Future<void> _loadPlayStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playCountsString = prefs.getString('playCounts');
      if (playCountsString != null) {
        final Map<String, dynamic> decoded = jsonDecode(playCountsString);
        _playCounts
          ..clear()
          ..addAll(decoded.map((k, v) => MapEntry(int.parse(k), v as int)));
      }
      final recentString = prefs.getString('recentPlays');
      if (recentString != null) {
        final List<dynamic> decodedList = jsonDecode(recentString);
        _recentPlays
          ..clear()
          ..addAll(
            decodedList.map<Map<String, dynamic>>((e) {
              return {"id": e["id"] as int, "ts": e["ts"] as int};
            }),
          );
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading play stats: $e");
    }
  }

  Future<void> _savePlayStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedCounts = _playCounts.map(
        (k, v) => MapEntry(k.toString(), v),
      );
      await prefs.setString('playCounts', jsonEncode(encodedCounts));
      await prefs.setString('recentPlays', jsonEncode(_recentPlays));
    } catch (e) {
      debugPrint("Error saving play stats: $e");
    }
  }

  void _recordPlay(int songId) {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      _recentPlays.insert(0, {"id": songId, "ts": now});
      if (_recentPlays.length > _recentPlaysCap) {
        _recentPlays.removeRange(_recentPlaysCap, _recentPlays.length);
      }
      _playCounts[songId] = (_playCounts[songId] ?? 0) + 1;
      _savePlayStats();
      notifyListeners();
    } catch (e) {
      debugPrint("Error recording play: $e");
    }
  }

  List<SongModel> getRecentlyPlayed({int limit = 20}) {
    final ids = _recentPlays.map((e) => e['id'] as int).toList();
    final List<SongModel> list = [];
    final seen = <int>{};
    for (var id in ids) {
      if (seen.contains(id)) continue;
      final song = _songs.firstWhere(
        (s) => s.id == id,
        orElse: () => null as SongModel,
      );
      if (song != null) {
        list.add(song);
        seen.add(id);
      }
      if (list.length >= limit) break;
    }
    return list;
  }

  List<SongModel> getMostListened({int limit = 20}) {
    final List<MapEntry<int, int>> counts = _playCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<SongModel> result = [];
    for (var entry in counts) {
      final song = _songs.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => null as SongModel,
      );
      if (song != null) {
        result.add(song);
      }
      if (result.length >= limit) break;
    }
    return result;
  }

  int getPlayCount(int songId) => _playCounts[songId] ?? 0;

  Future<void> clearRecentPlays() async {
    _recentPlays.clear();
    await _savePlayStats();
    notifyListeners();
  }

  Future<void> resetPlayCounts() async {
    _playCounts.clear();
    await _savePlayStats();
    notifyListeners();
  }

  List<Map<String, dynamic>> get rawRecentPlays =>
      List.unmodifiable(_recentPlays);
}
