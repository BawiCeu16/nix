import 'dart:typed_data';
import 'package:hive/hive.dart';

/// Centralized helper for loading artwork from the Hive `cached_images` box.
///
/// Eliminates duplicated try-catch + Hive lookup boilerplate across widgets.
class ArtworkHelper {
  ArtworkHelper._();

  /// Returns the cached artwork bytes for [songUri], or `null` if unavailable.
  ///
  /// This safely handles the case where the Hive box is not open or the key
  /// doesn't exist. Exceptions are silently caught and return `null`.
  static Uint8List? getArtwork(String? songUri) {
    if (songUri == null) return null;
    try {
      if (Hive.isBoxOpen('cached_images')) {
        final data = Hive.box('cached_images').get(songUri);
        if (data != null && data is Uint8List) return data;
      }
    } catch (_) {}
    return null;
  }

  /// Returns artwork for the first song in a list of URIs.
  ///
  /// Useful for album / artist pages that show a representative image
  /// from the first available song.
  static Uint8List? getFirstArtwork(List<String> songUris) {
    for (final uri in songUris) {
      final art = getArtwork(uri);
      if (art != null) return art;
    }
    return null;
  }
}
