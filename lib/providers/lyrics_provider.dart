import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/services/lyrics_service.dart';

/// Reactive provider managing active track lyrics state and position synchronization.
class LyricsProvider with ChangeNotifier {
  final LyricsService _service = LyricsService();

  SettingsProvider? _settingsProvider;
  CurrentMusicProvider? _currentMusicProvider;

  String? _plainLyrics;
  List<LyricLine>? _syncedLyrics;
  bool _isLoading = false;
  int? _fetchedTrackId;
  int _currentIndex = -1;
  bool _activeSync = false;

  StreamSubscription<Duration>? _positionSubscription;

  // Getters
  String? get plainLyrics => _plainLyrics;
  List<LyricLine>? get syncedLyrics => _syncedLyrics;
  bool get isLoading => _isLoading;
  int? get fetchedTrackId => _fetchedTrackId;
  int get currentIndex => _currentIndex;
  bool get activeSync => _activeSync;

  void update(SettingsProvider settings, CurrentMusicProvider currentMusic) {
    _settingsProvider = settings;
    final bool trackChanged =
        currentMusic.currentTrack?.id != _currentMusicProvider?.currentTrack?.id;
    _currentMusicProvider = currentMusic;

    if (trackChanged) {
      _fetchedTrackId = null;
      _plainLyrics = null;
      _syncedLyrics = null;
      _currentIndex = -1;
      _cancelPositionSubscription();

      if (_activeSync) {
        checkAndFetch();
      }
    }
  }

  void setActiveSync(bool active) {
    if (_activeSync == active) return;
    _activeSync = active;

    if (_activeSync) {
      checkAndFetch();
      _updatePositionListener();
    } else {
      _cancelPositionSubscription();
    }
  }

  void checkAndFetch() {
    final track = _currentMusicProvider?.currentTrack;
    if (track == null) return;

    final cacheKey = _service.getCacheKey(track.title, track.artist);
    final cached = _service.getCachedLyrics(cacheKey);

    if (cached != null) {
      if (track.id != _fetchedTrackId) {
        fetchLyrics(track);
      }
      return;
    }

    if (_activeSync && track.id != _fetchedTrackId) {
      fetchLyrics(track);
    }
  }

  Future<void> fetchLyrics(Track track) async {
    _isLoading = true;
    _plainLyrics = null;
    _syncedLyrics = null;
    _currentIndex = -1;
    _fetchedTrackId = track.id;
    notifyListeners();

    try {
      final saveOffline = _settingsProvider?.saveLyricsOffline ?? true;
      final data = await _service.fetchLyrics(track, saveOffline: saveOffline);

      if (data != null) {
        _handleLyricsData(data);
      } else {
        _plainLyrics = "Lyrics not found.";
        _syncedLyrics = null;
        notifyListeners();
      }
    } catch (e) {
      _plainLyrics = "Error fetching lyrics.";
      _syncedLyrics = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleLyricsData(Map<String, dynamic> data) {
    if (data['syncedLyrics'] != null &&
        data['syncedLyrics'].toString().isNotEmpty) {
      final parsed = _service.parseLrc(data['syncedLyrics']);
      if (parsed.isNotEmpty) {
        _syncedLyrics = parsed;
        _plainLyrics = null;
        notifyListeners();
        _updatePositionListener();
        return;
      }
    }
    _plainLyrics = data['plainLyrics'] ?? "Lyrics not found.";
    _syncedLyrics = null;
    notifyListeners();
    _updatePositionListener();
  }

  void _updatePositionListener() {
    final currentMusic = _currentMusicProvider;
    if (currentMusic == null) return;

    final isLyricsVisible = _activeSync;

    if (isLyricsVisible && _syncedLyrics != null) {
      final currentPos = currentMusic.position;
      _updateIndexForPosition(currentPos);

      _positionSubscription ??= currentMusic.positionStream.listen((pos) {
        _updateIndexForPosition(pos);
      });
    } else {
      _cancelPositionSubscription();
    }
  }

  void _updateIndexForPosition(Duration pos) {
    final lyrics = _syncedLyrics;
    if (lyrics == null || lyrics.isEmpty) return;

    int low = 0;
    int high = lyrics.length - 1;
    int newIndex = -1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      if (lyrics[mid].time <= pos) {
        newIndex = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (newIndex != _currentIndex && newIndex != -1) {
      _currentIndex = newIndex;
      notifyListeners();
    }
  }

  void _cancelPositionSubscription() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<List<dynamic>?> searchLyrics(String title, String artist) async {
    _isLoading = true;
    notifyListeners();

    try {
      final query = '$title $artist'.trim();
      return await _service.searchLyrics(query);
    } catch (e) {
      debugPrint('Error searching lyrics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  void selectManualLyrics(Map<String, dynamic> result, String cacheKey) {
    _handleLyricsData(result);
    final settings = _settingsProvider;
    if (settings?.saveLyricsOffline == true) {
      _service.saveLyricsToCache(cacheKey, result);
    }
  }

  void setLyricsNotFound() {
    _plainLyrics = "Lyrics not found.";
    _syncedLyrics = null;
    notifyListeners();
  }

  void setLyricsError() {
    _plainLyrics = "Error fetching lyrics.";
    _syncedLyrics = null;
    notifyListeners();
  }

  String getCacheKey(String title, String? artist) {
    return _service.getCacheKey(title, artist);
  }

  @override
  void dispose() {
    _cancelPositionSubscription();
    super.dispose();
  }
}
