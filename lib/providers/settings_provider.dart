import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/models/settings/artwork_quality.dart';
import 'package:nix/models/settings/timer_gesture.dart';

enum AccentColorMode { dynamic, device, custom }

enum ArtworkShape {
  rounded,
  circle,
}

enum NavbarStyle { floating, standard }

/// Manages app-wide settings like theme, accent color, and playback behaviors.
/// Settings are persisted to the Hive.
class SettingsProvider with ChangeNotifier {
  Box get _box => Hive.box(HiveKeys.settingsBox);

  // Auto Play
  /// Whether the player should automatically play the next track or random
  bool get autoPlay => _box.get(HiveKeys.autoPlay, defaultValue: true);

  void setAutoPlay(bool value) {
    _box.put(HiveKeys.autoPlay, value);
    notifyListeners();
  }

  // Theme Mode
  /// The current theme mode (Light, Dark, or System)
  ThemeMode get themeMode {
    final String mode = _box.get(HiveKeys.themeMode, defaultValue: 'system');
    return ThemeMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => ThemeMode.system,
    );
  }

  void setThemeMode(ThemeMode mode) {
    _box.put(HiveKeys.themeMode, mode.name);
    notifyListeners();
  }

  // Accent Color Mode
  /// Defines how the accent color is determined.
  AccentColorMode get accentColorMode {
    final String mode = _box.get(
      HiveKeys.accentColorMode,
      defaultValue: 'dynamic',
    );
    return AccentColorMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => AccentColorMode.dynamic,
    );
  }

  void setAccentColorMode(AccentColorMode mode) {
    _box.put(HiveKeys.accentColorMode, mode.name);
    notifyListeners();
  }

  // Custom Accent Color
  /// The fallback custom accent color when AccentColorMode.custom is used.
  Color get customAccentColor {
    final int colorValue = _box.get(
      HiveKeys.customAccentColor,
      defaultValue: Colors.blue.value,
    );
    return Color(colorValue);
  }

  void setCustomAccentColor(Color color) {
    _box.put(HiveKeys.customAccentColor, color.value);
    notifyListeners();
  }

  // Swipe to Dismiss
  /// Whether the user can dismiss the player by swiping down fully.
  bool get swipeToDismiss =>
      _box.get(HiveKeys.swipeToDismiss, defaultValue: true);

  void setSwipeToDismiss(bool value) {
    _box.put(HiveKeys.swipeToDismiss, value);
    notifyListeners();
  }

  // Minimum Duration
  /// Filter out songs with duration less than this (in seconds).
  int get minDuration => _box.get(HiveKeys.minDuration, defaultValue: 0);

  void setMinDuration(int seconds) {
    _box.put(HiveKeys.minDuration, seconds);
    notifyListeners();
  }

  // Haptic Feedback
  /// Whether haptic feedback (vibration) is enabled for major actions.
  bool get enableHaptics =>
      _box.get(HiveKeys.enableHaptics, defaultValue: true);

  void setEnableHaptics(bool value) {
    _box.put(HiveKeys.enableHaptics, value);
    notifyListeners();
  }

  // Playback Speed
  /// The current playback speed multiplier (e.g., 1.0, 1.5).
  double get playbackSpeed =>
      _box.get(HiveKeys.playbackSpeed, defaultValue: 1.0);

  void setPlaybackSpeed(double value) {
    _box.put(HiveKeys.playbackSpeed, value);
    notifyListeners();
  }

  // Reset Speed on New Track
  /// Whether the playback speed should reset to 1.0 when a new track starts.
  bool get resetSpeedOnNewTrack =>
      _box.get(HiveKeys.resetSpeedOnNewTrack, defaultValue: true);

  void setResetSpeedOnNewTrack(bool value) {
    _box.put(HiveKeys.resetSpeedOnNewTrack, value);
    notifyListeners();
  }

  // Skip Silence
  /// Whether the player should automatically skip silent parts in the audio.
  bool get skipSilence => _box.get(HiveKeys.skipSilence, defaultValue: false);

  void setSkipSilence(bool value) {
    _box.put(HiveKeys.skipSilence, value);
    notifyListeners();
  }

  // Appearance - AMOLED Mode
  /// Whether to use pure black (#000000) for dark mode.
  bool get useAmoledMode =>
      _box.get(HiveKeys.useAmoledMode, defaultValue: false);

  void setUseAmoledMode(bool value) {
    _box.put(HiveKeys.useAmoledMode, value);
    notifyListeners();
  }

  // Appearance - Artwork Shape
  /// The global geometric shape for all artwork.
  ArtworkShape get artworkShape {
    final String shape = _box.get(
      HiveKeys.artworkShape,
      defaultValue: 'rounded',
    );
    return ArtworkShape.values.firstWhere(
      (e) => e.name == shape,
      orElse: () => ArtworkShape.rounded,
    );
  }

  void setArtworkShape(ArtworkShape shape) {
    _box.put(HiveKeys.artworkShape, shape.name);
    notifyListeners();
  }

  // Appearance - Artwork Quality
  /// The global resolution for all artwork.
  NixArtworkQuality get artworkQuality {
    final String quality = _box.get(
      HiveKeys.artworkQuality,
      defaultValue: 'high',
    );
    return NixArtworkQuality.values.firstWhere(
      (e) => e.name == quality,
      orElse: () => NixArtworkQuality.high,
    );
  }

  void setArtworkQuality(NixArtworkQuality quality) {
    _box.put(HiveKeys.artworkQuality, quality.name);
    notifyListeners();
  }

  // Appearance - Timer Gesture
  /// The interaction type for the floating sleep timer indicator.
  TimerGesture get timerGesture {
    final String gesture = _box.get(
      HiveKeys.timerGesture,
      defaultValue: 'longPress',
    );
    return TimerGesture.values.firstWhere(
      (e) => e.name == gesture,
      orElse: () => TimerGesture.longPress,
    );
  }

  void setTimerGesture(TimerGesture gesture) {
    _box.put(HiveKeys.timerGesture, gesture.name);
    notifyListeners();
  }

  // Search History
  /// List of recent search queries.
  List<String> get searchHistory {
    final List<dynamic> history = _box.get(
      HiveKeys.searchHistory,
      defaultValue: [],
    );
    return history.cast<String>();
  }

  void addSearchQuery(String query) {
    if (query.isEmpty) return;
    final List<String> history = searchHistory;
    history.remove(query); // Remove if exists to move to top
    history.insert(0, query);
    if (history.length > 10) history.removeLast(); // Limit to 10
    _box.put(HiveKeys.searchHistory, history);
    notifyListeners();
  }

  void removeSearchQuery(String query) {
    final List<String> history = searchHistory;
    history.remove(query);
    _box.put(HiveKeys.searchHistory, history);
    notifyListeners();
  }

  void clearSearchHistory() {
    _box.put(HiveKeys.searchHistory, []);
    notifyListeners();
  }
}
