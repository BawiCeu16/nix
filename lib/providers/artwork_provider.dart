import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:nix/models/settings/artwork_quality.dart';

/// Request item queued for background artwork extraction.
class _ArtworkFetchRequest {
  final int id;
  final ArtworkType type;
  final NixArtworkQuality quality;
  final String key;

  const _ArtworkFetchRequest({
    required this.id,
    required this.type,
    required this.quality,
    required this.key,
  });
}

/// A high-performance, non-blocking artwork provider.
///
/// Features:
/// - Fast in-memory LRU cache (LinkedHashMap, 350 capacity).
/// - Bounded concurrency worker pool (max 4 concurrent fetches) to eliminate
///   platform channel saturation and binary messenger jank during fast scrolling.
/// - LIFO (Last-In-First-Out) priority queue ensuring visible viewport items
///   are fetched first before scrolled-past items.
/// - Isolated per-key [ValueNotifier] reactivity: fetching item X updates ONLY
///   item X's widget, with zero global selector/ChangeNotifier churn.
/// - Synchronous cache fast-path for instantaneous 0-frame rendering.
class ArtworkProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery;

  static const int _maxCacheSize = 350;
  static const int _maxConcurrentFetches = 4;

  // In-memory LRU cache (LinkedHashMap preserves insertion order)
  final Map<String, Uint8List?> _cache = {};

  // Per-key ValueNotifiers for fine-grained, isolated widget updates
  final Map<String, ValueNotifier<Uint8List?>> _notifiers = {};

  // LIFO queue for pending fetches (newest visible items at index 0)
  final List<_ArtworkFetchRequest> _queue = [];

  // Keys currently in the queue or being processed
  final Set<String> _pendingKeys = {};

  int _activeFetches = 0;

  ArtworkProvider({OnAudioQuery? audioQuery})
    : _audioQuery = audioQuery ?? OnAudioQuery();

  /// Synchronously checks whether the artwork is cached in memory.
  /// Returns cached bytes immediately, or `null` if not cached.
  Uint8List? getSync(int id, ArtworkType type, NixArtworkQuality quality) {
    final key = _generateKey(id, type, quality);
    if (_cache.containsKey(key)) {
      final bytes = _cache.remove(key);
      _cache[key] = bytes; // Move to end of iteration (most recently used)
      return bytes;
    }
    return null;
  }

  /// Whether the artwork key has already been queried and cached (even if null/placeholder).
  bool isCached(int id, ArtworkType type, NixArtworkQuality quality) {
    final key = _generateKey(id, type, quality);
    return _cache.containsKey(key);
  }

  /// Returns an isolated [ValueListenable] for the given artwork.
  ///
  /// If cached, the notifier immediately contains the cached [Uint8List].
  /// If not cached, the fetch is enqueued in the background worker pool and
  /// this notifier will update as soon as the artwork is ready.
  ValueListenable<Uint8List?> getArtworkNotifier(
    int id,
    ArtworkType type,
    NixArtworkQuality quality,
  ) {
    final key = _generateKey(id, type, quality);

    if (_cache.containsKey(key)) {
      final cachedBytes = _cache.remove(key);
      _cache[key] = cachedBytes;

      final existingNotifier = _notifiers[key];
      if (existingNotifier != null) {
        if (existingNotifier.value != cachedBytes) {
          existingNotifier.value = cachedBytes;
        }
        return existingNotifier;
      }
      final notifier = ValueNotifier<Uint8List?>(cachedBytes);
      _notifiers[key] = notifier;
      return notifier;
    }

    final notifier = _notifiers.putIfAbsent(
      key,
      () => ValueNotifier<Uint8List?>(null),
    );

    _enqueueFetch(id, type, quality, key);

    return notifier;
  }

  /// Backward-compatible method: retrieves cached artwork or triggers background fetch.
  Uint8List? getCachedArtwork(
    int id,
    ArtworkType type,
    NixArtworkQuality quality,
  ) {
    final key = _generateKey(id, type, quality);

    if (_cache.containsKey(key)) {
      final bytes = _cache.remove(key);
      _cache[key] = bytes;
      return bytes;
    }

    _enqueueFetch(id, type, quality, key);
    return null;
  }

  void _enqueueFetch(
    int id,
    ArtworkType type,
    NixArtworkQuality quality,
    String key,
  ) {
    if (_pendingKeys.contains(key) || _cache.containsKey(key)) {
      return;
    }

    _pendingKeys.add(key);
    // LIFO priority: Insert at the start so newly visible items are fetched first
    _queue.insert(
      0,
      _ArtworkFetchRequest(id: id, type: type, quality: quality, key: key),
    );

    _processQueue();
  }

  void _processQueue() {
    while (_activeFetches < _maxConcurrentFetches && _queue.isNotEmpty) {
      final request = _queue.removeAt(0);
      _activeFetches++;
      _executeFetch(request);
    }
  }

  Future<void> _executeFetch(_ArtworkFetchRequest request) async {
    try {
      final isMobile =
          !kIsWeb &&
          (Platform.isAndroid ||
              Platform.isIOS ||
              Platform.environment.containsKey('FLUTTER_TEST'));
      if (!isMobile) {
        _putInCache(request.key, null);
        return;
      }

      final format = request.quality == NixArtworkQuality.high
          ? ArtworkFormat.PNG
          : ArtworkFormat.JPEG;

      int size;
      switch (request.quality) {
        case NixArtworkQuality.high:
          size = 500;
          break;
        case NixArtworkQuality.medium:
          size = 250;
          break;
        case NixArtworkQuality.low:
          size = 120;
          break;
      }

      final bytes = await _audioQuery.queryArtwork(
        request.id,
        request.type,
        format: format,
        size: size,
      );

      _putInCache(request.key, bytes);
      final notifier = _notifiers[request.key];
      if (notifier != null) {
        notifier.value = bytes;
      }
    } catch (e) {
      debugPrint('Error fetching artwork ${request.id}: $e');
      _putInCache(request.key, null);
      final notifier = _notifiers[request.key];
      if (notifier != null) {
        notifier.value = null;
      }
    } finally {
      _pendingKeys.remove(request.key);
      _activeFetches--;
      _processQueue();
    }
  }

  void _putInCache(String key, Uint8List? bytes) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[key] = bytes;
  }

  String _generateKey(int id, ArtworkType type, NixArtworkQuality quality) {
    return '${type.name}_${id}_${quality.name}';
  }

  /// Clears in-memory artwork cache, resets queue, and notifies active listeners.
  void clearCache() {
    _cache.clear();
    _queue.clear();
    _pendingKeys.clear();
    for (final notifier in _notifiers.values) {
      notifier.value = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }
    _notifiers.clear();
    _queue.clear();
    _pendingKeys.clear();
    super.dispose();
  }
}
