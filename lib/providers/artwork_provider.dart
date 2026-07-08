import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:nix/models/settings/artwork_quality.dart';

class ArtworkProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Cache for artwork bytes
  final Map<String, Uint8List?> _cache = {};

  // Tracks currently being fetched to avoid duplicate calls
  final Set<String> _pending = {};

  /// Retrieves artwork bytes from cache or initiates a background fetch.
  Uint8List? getCachedArtwork(
    int id,
    ArtworkType type,
    NixArtworkQuality quality,
  ) {
    final key = _generateKey(id, type, quality);

    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    if (!_pending.contains(key)) {
      Future.microtask(() => _fetchArtwork(id, type, quality));
    }

    return null;
  }

  Future<void> _fetchArtwork(
    int id,
    ArtworkType type,
    NixArtworkQuality quality,
  ) async {
    final key = _generateKey(id, type, quality);
    _pending.add(key);

    try {
      final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      if (!isMobile) {
        _cache[key] = null;
        return;
      }
      // Tiered logic moved to provider
      final format = quality == NixArtworkQuality.high
          ? ArtworkFormat.PNG
          : ArtworkFormat.JPEG;

      int size;
      switch (quality) {
        case NixArtworkQuality.high:
          size = 500; // Native QueryArtworkWidget high default
          break;
        case NixArtworkQuality.medium:
          size = 250;
          break;
        case NixArtworkQuality.low:
          size = 120;
          break;
      }

      final bytes = await _audioQuery.queryArtwork(
        id,
        type,
        format: format,
        size: size,
      );

      _cache[key] = bytes;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching artwork $id: $e');
      _cache[key] = null; // Mark as null to avoid re-fetching failed art
    } finally {
      _pending.remove(key);
    }
  }

  String _generateKey(int id, ArtworkType type, NixArtworkQuality quality) {
    return '${type.name}_${id}_${quality.name}';
  }

  void clearCache() {
    _cache.clear();
    _pending.clear();
    notifyListeners();
  }
}
