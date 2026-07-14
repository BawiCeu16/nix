import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/providers/current_music_provider.dart';

class LyricLine {
  final Duration time;
  final String text;

  LyricLine(this.time, this.text);
}

class LyricsProvider with ChangeNotifier {
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
    final bool trackChanged = currentMusic.currentTrack?.id != _currentMusicProvider?.currentTrack?.id;
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

    final cacheKey = _getCacheKey(track.title, track.artist);
    final box = Hive.box(HiveKeys.lyricsBox);

    if (box.containsKey(cacheKey)) {
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
    final title = _cleanTitle(track.title, track.artist);
    final cacheKey = _getCacheKey(track.title, track.artist);
    final box = Hive.box(HiveKeys.lyricsBox);
    final settings = _settingsProvider;

    if (box.containsKey(cacheKey)) {
      try {
        final cachedValue = box.get(cacheKey);
        if (cachedValue != null) {
          final Map<String, dynamic> mapData = Map<String, dynamic>.from(
            cachedValue is String ? json.decode(cachedValue) : cachedValue,
          );
          _plainLyrics = null;
          _syncedLyrics = null;
          _currentIndex = -1;
          _isLoading = false;
          _fetchedTrackId = track.id;
          _handleLyricsData(mapData);
          return;
        }
      } catch (e) {
        // Fallback to fetch if corrupted
      }
    }

    _isLoading = true;
    _plainLyrics = null;
    _syncedLyrics = null;
    _currentIndex = -1;
    _fetchedTrackId = track.id;
    notifyListeners();

    try {
      final queryParams = {
        'track_name': title,
        'artist_name': track.artist,
        'album_name': track.album,
        'duration': (track.duration ~/ 1000).toString(),
      };

      final uri = Uri.parse(
        'https://lrclib.net/api/get',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _handleLyricsData(data);
        if (settings?.saveLyricsOffline == true) {
          box.put(cacheKey, json.encode(data));
        }
      } else {
        final searchUri = Uri.parse(
          'https://lrclib.net/api/search',
        ).replace(queryParameters: queryParams);
        final searchResponse = await http.get(searchUri);

        if (searchResponse.statusCode == 200) {
          final List searchData = json.decode(searchResponse.body);
          if (searchData.isNotEmpty) {
            _handleLyricsData(searchData.first);
            if (settings?.saveLyricsOffline == true) {
              box.put(cacheKey, json.encode(searchData.first));
            }
          } else {
            _plainLyrics = "Lyrics not found.";
            _syncedLyrics = null;
            notifyListeners();
          }
        } else {
          _plainLyrics = "Lyrics not found.";
          _syncedLyrics = null;
          notifyListeners();
        }
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
      final parsed = _parseLrc(data['syncedLyrics']);
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
    if (_syncedLyrics == null) return;
    int newIndex = -1;
    for (int i = 0; i < _syncedLyrics!.length; i++) {
      if (pos >= _syncedLyrics![i].time) {
        newIndex = i;
      } else {
        break;
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
      final queryParams = {'q': query};

      final searchUri = Uri.parse(
        'https://lrclib.net/api/search',
      ).replace(queryParameters: queryParams);
      final searchResponse = await http.get(searchUri);

      if (searchResponse.statusCode == 200) {
        final List searchData = json.decode(searchResponse.body);
        return searchData;
      }
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
      Hive.box(HiveKeys.lyricsBox).put(cacheKey, json.encode(result));
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

  List<LyricLine> _parseLrc(String lrc) {
    final lines = lrc.split('\n');
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    List<LyricLine> parsedLines = [];

    for (var line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        int milliseconds = int.parse(match.group(3)!);
        if (match.group(3)!.length == 2) {
          milliseconds *= 10;
        }

        final text = match.group(4)!.trim();
        if (text.isNotEmpty) {
          parsedLines.add(
            LyricLine(
              Duration(
                minutes: minutes,
                seconds: seconds,
                milliseconds: milliseconds,
              ),
              text,
            ),
          );
        }
      }
    }
    return parsedLines;
  }

  String _cleanTitle(String title, String? artist) {
    if (artist == null || artist.isEmpty) return title;
    String cleaned = title;

    final lowerTitle = title.toLowerCase();
    final lowerArtist = artist.toLowerCase();

    if (lowerTitle.contains(lowerArtist)) {
      final regex = RegExp(
        r'\s*[-\u2010-\u2015]\s*' +
            RegExp.escape(artist) +
            r'|\s*' +
            RegExp.escape(artist) +
            r'\s*[-\u2010-\u2015]\s*',
        caseSensitive: false,
      );
      if (regex.hasMatch(cleaned)) {
        cleaned = cleaned.replaceAll(regex, '');
      } else {
        final regex2 = RegExp(RegExp.escape(artist), caseSensitive: false);
        cleaned = cleaned.replaceAll(regex2, '').trim();
      }
    }

    cleaned = cleaned.replaceAll(RegExp(r'\(\s*\)'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\[\s*\]'), '').trim();

    return cleaned.isNotEmpty ? cleaned : title;
  }

  String _getCacheKey(String title, String? artist) {
    return "${title.toLowerCase().trim()}_${(artist ?? '').toLowerCase().trim()}";
  }

  String getCacheKey(String title, String? artist) {
    return _getCacheKey(title, artist);
  }

  @override
  void dispose() {
    _cancelPositionSubscription();
    super.dispose();
  }
}
