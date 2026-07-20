import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/models/music/track.dart';

/// Single line of synchronized lyrics with timestamp.
class LyricLine {
  final Duration time;
  final String text;

  LyricLine(this.time, this.text);
}

/// Encapsulates LRCLIB API network fetching, LRC string parsing, title cleaning, and offline Hive caching.
class LyricsService {
  /// Fetches lyrics for a track, checking local Hive cache first, then LRCLIB API.
  Future<Map<String, dynamic>?> fetchLyrics(
    Track track, {
    required bool saveOffline,
  }) async {
    final cacheKey = getCacheKey(track.title, track.artist);

    // Check Hive cache first
    final cachedData = getCachedLyrics(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    final title = cleanTitle(track.title, track.artist);
    final queryParams = {
      'track_name': title,
      'artist_name': track.artist,
      'album_name': track.album,
      'duration': (track.duration ~/ 1000).toString(),
    };

    try {
      final uri = Uri.parse(
        'https://lrclib.net/api/get',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (saveOffline) {
          saveLyricsToCache(cacheKey, data);
        }
        return data;
      }

      // Fallback search if exact get fails
      final searchUri = Uri.parse(
        'https://lrclib.net/api/search',
      ).replace(queryParameters: queryParams);
      final searchResponse = await http.get(searchUri);

      if (searchResponse.statusCode == 200) {
        final List searchData = json.decode(searchResponse.body);
        if (searchData.isNotEmpty) {
          final Map<String, dynamic> firstResult = Map<String, dynamic>.from(
            searchData.first,
          );
          if (saveOffline) {
            saveLyricsToCache(cacheKey, firstResult);
          }
          return firstResult;
        }
      }
    } catch (e) {
      debugPrint('Error fetching lyrics from LRCLIB: $e');
    }

    return null;
  }

  /// Searches for lyrics by a raw query string.
  Future<List<dynamic>?> searchLyrics(String query) async {
    try {
      final queryParams = {'q': query.trim()};
      final searchUri = Uri.parse(
        'https://lrclib.net/api/search',
      ).replace(queryParameters: queryParams);
      final searchResponse = await http.get(searchUri);

      if (searchResponse.statusCode == 200) {
        return json.decode(searchResponse.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error searching lyrics: $e');
    }
    return null;
  }

  /// Parses synchronized LRC formatted text into structured [LyricLine]s.
  List<LyricLine> parseLrc(String lrc) {
    final lines = lrc.split('\n');
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    final List<LyricLine> parsedLines = [];

    for (final line in lines) {
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

  /// Sanitizes song title by removing repetitive artist names and bracketed noise.
  String cleanTitle(String title, String? artist) {
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

  /// Generates a standardized cache key.
  String getCacheKey(String title, String? artist) {
    return "${title.toLowerCase().trim()}_${(artist ?? '').toLowerCase().trim()}";
  }

  /// Retrieves cached lyrics map from Hive if present.
  Map<String, dynamic>? getCachedLyrics(String cacheKey) {
    if (!Hive.isBoxOpen(HiveKeys.lyricsBox)) return null;
    final box = Hive.box(HiveKeys.lyricsBox);

    if (box.containsKey(cacheKey)) {
      try {
        final cachedValue = box.get(cacheKey);
        if (cachedValue != null) {
          return Map<String, dynamic>.from(
            cachedValue is String ? json.decode(cachedValue) : cachedValue,
          );
        }
      } catch (e) {
        debugPrint('Error reading lyrics cache for $cacheKey: $e');
      }
    }
    return null;
  }

  /// Persists lyrics JSON to the Hive cache box.
  void saveLyricsToCache(String cacheKey, Map<String, dynamic> data) {
    if (!Hive.isBoxOpen(HiveKeys.lyricsBox)) return;
    Hive.box(HiveKeys.lyricsBox).put(cacheKey, json.encode(data));
  }
}
