import 'package:flutter/widgets.dart';
import 'package:flutter_remix/flutter_remix.dart';

class NixIcons {
  /// Maps a code point back to a constant IconData to support icon tree shaking in release builds.
  static IconData getPlaylistIcon(int? codePoint) {
    if (codePoint == null) return FlutterRemix.play_list_2_line;

    if (codePoint == FlutterRemix.play_list_2_line.codePoint) {
      return FlutterRemix.play_list_2_line;
    }
    if (codePoint == FlutterRemix.heart_3_line.codePoint) {
      return FlutterRemix.heart_3_line;
    }
    if (codePoint == FlutterRemix.star_line.codePoint) {
      return FlutterRemix.star_line;
    }
    if (codePoint == FlutterRemix.fire_line.codePoint) {
      return FlutterRemix.fire_line;
    }
    if (codePoint == FlutterRemix.music_2_line.codePoint) {
      return FlutterRemix.music_2_line;
    }
    if (codePoint == FlutterRemix.mic_2_line.codePoint) {
      return FlutterRemix.mic_2_line;
    }
    if (codePoint == FlutterRemix.headphone_line.codePoint) {
      return FlutterRemix.headphone_line;
    }
    if (codePoint == FlutterRemix.disc_line.codePoint) {
      return FlutterRemix.disc_line;
    }

    // Default fallback
    return FlutterRemix.play_list_2_line;
  }
}
