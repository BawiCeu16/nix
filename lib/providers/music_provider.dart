import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
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

  // ✅ Constructor
  MusicProvider() {
    loadFavorites();
    _listenToPlayerStreams();
    checkAndLoadSongs(); // ✅ NEW: Auto-load if permission is already granted
  }

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
    await _buildPlaylist(); // ✅ Build playlist right after loading songs
    _isLoading = false;
    notifyListeners();
  }

  // ✅ Refresh songs manually
  Future<void> refreshSongs() async {
    _songs = await _audioQuery.querySongs();
    _applySort();
    notifyListeners();
  }

  // ✅ Listen for player updates
  void _listenToPlayerStreams() {
    // Position updates
    _audioPlayer.positionStream.listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });

    // Duration updates
    _audioPlayer.durationStream.listen((dur) {
      _totalDuration = dur ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      notifyListeners();
    });

    // ✅ Track change updates (system next/previous buttons)
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _songs.length) {
        _currentSong = _songs[index];
        _cachedArtworkData = null; // Clear old artwork
        notifyListeners();
      }
    });
  }

  // ✅ Sorting
  void setSortOption(SortOption option) {
    _sortOption = option;
    _applySort();
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

  // ✅ Favorites
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

  // ✅ Search
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

  // ✅ Upcoming Songs
  List<SongModel> get upcomingSongs {
    if (_currentSong == null) return [];
    final index = _songs.indexOf(_currentSong!);
    if (index == -1 || index >= _songs.length - 1) return [];
    return _songs.sublist(index + 1);
  }

  // ✅ Show next song if current song ending soon (<20s left)
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

  // ✅ Mini Player toggle
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

  // ✅ Artwork
  Future<Uint8List?> fetchArtwork(int songId) async {
    _cachedArtworkData = await _audioQuery.queryArtwork(
      songId,
      ArtworkType.AUDIO,
      size: 700,
    );
    notifyListeners();
    return _cachedArtworkData;
  }

  // ✅ Playback controls
  Future<void> playSong(SongModel song) async {
    final index = _songs.indexOf(song);
    if (index == -1) return;

    try {
      if (_playlist == null) {
        await _buildPlaylist(); // ✅ Always rebuild after reset
      }

      await _audioPlayer.setAudioSource(
        _playlist!,
        initialIndex: index,
      ); // ✅ Fresh source
      await _audioPlayer.play();

      _currentSong = song;
      _cachedArtworkData = null;
      notifyListeners();
      getConnectedBluetoothDevice();
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  Future<void> playNext() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
      await _audioPlayer.play();
    }
  }

  Future<void> playPrevious() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
      await _audioPlayer.play();
    }
  }

  void pause() {
    _audioPlayer.pause();
  }

  void resume() {
    _audioPlayer.play();
  }

  void stop() {
    _audioPlayer.stop();
  }

  // Future<void> playNext() async => await _audioPlayer.seekToNext();
  // Future<void> playPrevious() async => await _audioPlayer.seekToPrevious();

  Future<void> _buildPlaylist() async {
    _playlist = ConcatenatingAudioSource(
      children: _songs.map((song) {
        return AudioSource.uri(
          Uri.parse(song.uri!),
          tag: MediaItem(
            id: song.id.toString(),
            album: song.album ?? 'Unknown Album',
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            artUri: Uri.parse('asset:///${song.id}'),
          ),
        );
      }).toList(),
    );
  }

  // ✅ Shuffle & Repeat integrated with just_audio
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

  // ✅ Clear current song
  Future<void> clearCurrentSong() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []));
      _playlist = null; // Force rebuild on next play
      _currentSong = null;
      _cachedArtworkData = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing current song: $e");
    }
  }

  // ✅ Stream for position updates (throttled)
  Stream<Duration> get throttledPositionStream => _audioPlayer.positionStream
      .throttleTime(const Duration(milliseconds: 500));

  void seek(Duration position) => _audioPlayer.seek(position);

  // ✅ Share current song
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

  // ✅ Get connected Bluetooth device
  Future<void> getConnectedBluetoothDevice() async {
    try {
      final String result = await _channel.invokeMethod(
        'getBluetoothDeviceName',
      );
      _connectedDeviceName = result;
    } catch (e) {
      _connectedDeviceName = "Unknown device";
      debugPrint("Error fetching device name: $e");
    }
    notifyListeners();
  }
}
