// providers/music_provider.dart
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
  /// play counts persisted as Map<int(songId) -> int(count)>
  final Map<int, int> _playCounts = {};

  /// recent plays: list of {"id": songId, "ts": epochMillis}
  final List<Map<String, dynamic>> _recentPlays = [];

  /// cap
  static const int _recentPlaysCap = 200; // keep latest 200 plays

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

  // ✅ Playlists etc.
  Map<String, List<int>> get playlists => _playlists;
  String? get currentPlaylist => _currentPlaylist;

  List<Map<String, dynamic>> get lyrics => _lyrics;
  int get currentLyricIndex => _currentLyricIndex;

  // ---------- Constructor ----------
  MusicProvider() {
    loadFavorites();
    _loadPlaylists();
    _loadPlayStats();
    _listenToPlayerStreams();
    checkAndLoadSongs();
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
      if (index != null && index >= 0 && index < _songs.length) {
        _currentSong = _songs[index];
        _cachedArtworkData = null;

        // fetch lyrics
        if (_currentSong != null) {
          fetchLyricsFromLrcLib(
            _currentSong!.title,
            _currentSong!.artist ?? "Unknown",
          );
        }
      } else {
        _currentSong = null;
      }
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      // no automatic counting here — clicks only
      notifyListeners();
    });
  }

  // ---------- Sorting ----------
  /// Public setter that rebuilds the internal audio playlist and preserves playback.
  Future<void> setSortOption(SortOption option) async {
    _sortOption = option;
    _applySort();

    // Rebuild the concatenating audio source so order in audio player matches UI.
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

  /// Rebuild the ConcatenatingAudioSource when the list order changes,
  /// trying to preserve current index, position and playback state.
  Future<void> _rebuildPlaylistPreservePlayback() async {
    try {
      // store playback state
      final wasPlaying = _audioPlayer.playing;
      final currentPosition = _audioPlayer.position;
      final currentSongId = _currentSong?.id;

      // rebuild playlist from current _songs order
      _playlist = ConcatenatingAudioSource(
        children: _songs.map((song) {
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

      // determine initial index (prefer currentSong if still present)
      int initialIndex = 0;
      if (currentSongId != null) {
        final newIndex = _songs.indexWhere((s) => s.id == currentSongId);
        if (newIndex != -1) initialIndex = newIndex;
      }

      // set audio source with initialIndex; then restore position & playing state
      await _audioPlayer.setAudioSource(_playlist!, initialIndex: initialIndex);
      // seek to stored position on the selected index
      await _audioPlayer.seek(currentPosition, index: initialIndex);

      if (wasPlaying) {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("Error rebuilding playlist: $e");
    }
  }

  // ---------- Favorites ----------
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteSongIds =
        prefs.getStringList('favorites')?.map(int.parse).toList() ?? [];
    notifyListeners();
  }

  Future<void> toggleFavorite(int songId) async {
    final prefs = await SharedPreferences.getInstance();

    if (_favoriteSongIds.contains(songId)) {
      _favoriteSongIds.remove(songId);
    } else {
      _favoriteSongIds.add(songId);
    }

    await prefs.setStringList(
      'favorites',
      _favoriteSongIds.map((id) => id.toString()).toList(),
    );
    notifyListeners();
  }

  bool isFavorite(int songId) => _favoriteSongIds.contains(songId);

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
    if (_currentSong == null) return [];
    final index = _songs.indexOf(_currentSong!);
    if (index == -1 || index >= _songs.length - 1) return [];
    return _songs.sublist(index + 1);
  }

  SongModel? get nextSongIfEndingSoon {
    if (_currentSong == null || _totalDuration == Duration.zero) return null;
    final remaining = _totalDuration - _currentPosition;
    if (remaining.inSeconds <= 20) {
      final index = _songs.indexOf(_currentSong!);
      if (index != -1 && index < _songs.length - 1) {
        return _songs[index + 1];
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

  // Convenience: record click then play
  Future<void> recordClickAndPlay(SongModel song) async {
    recordSongClick(song.id);
    await playSong(song);
  }

  // Public API: record a click (counts + recents)
  void recordSongClick(int songId) {
    _recordPlay(songId);
  }

  /// Play next track and increment listen count for the newly selected song.
  Future<void> playNext() async {
    try {
      if (_audioPlayer.hasNext) {
        await _audioPlayer.seekToNext();
      } else {
        // Optional: loop to first track
        await _audioPlayer.seek(Duration.zero, index: 0);
      }

      await _audioPlayer.play();

      // After seeking, get the current index and record the play for that song
      final idx = _audioPlayer.currentIndex;
      if (idx != null && idx >= 0 && idx < _songs.length) {
        final s = _songs[idx];
        _recordPlay(s.id);
      }
    } catch (e) {
      debugPrint("Error in playNext: $e");
    }
  }

  /// Play previous track and increment listen count for the newly selected song.
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
      if (idx != null && idx >= 0 && idx < _songs.length) {
        final s = _songs[idx];
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
    _playlist = ConcatenatingAudioSource(
      children: _songs.map((song) {
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

  // ---------- Shuffle & Repeat ----------
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

  // ---------- Clear / stop ----------
  Future<void> clearCurrentSong() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []));
      _playlist = null;
      _currentSong = null;
      _cachedArtworkData = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing current song: $e");
    }
  }

  // ---------- Position stream ----------
  Stream<Duration> get throttledPositionStream => _audioPlayer.positionStream
      .throttleTime(const Duration(milliseconds: 500));

  get currentLine => null;
  void seek(Duration position) => _audioPlayer.seek(position);

  // ---------- Playlists ----------
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

    final children = <AudioSource>[];
    for (var song in playlistSongs) {
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

    _currentSong = playlistSongs.first;
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

  // Future<void> _ensureBluetoothPermission() async {
  //   if (!Platform.isAndroid) return;
  //   final status = await Permission.bluetoothConnect.status;
  //   if (!status.isGranted) {
  //     await Permission.bluetoothConnect.request();
  //   }
  // }

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

        // Sync with song position
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
