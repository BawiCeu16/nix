import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/models/settings/artwork_quality.dart';
import 'package:nix/models/settings/timer_gesture.dart';
import 'package:nix/providers/settings_provider.dart';

/// Handles low-level Hive box reads, writes, and defaults for application settings.
class SettingsRepository {
  Box get _box => Hive.box(HiveKeys.settingsBox);

  // Auto Play
  bool get autoPlay => _box.get(HiveKeys.autoPlay, defaultValue: false);
  Future<void> setAutoPlay(bool value) => _box.put(HiveKeys.autoPlay, value);

  // Theme Mode
  ThemeMode get themeMode {
    final String mode = _box.get(HiveKeys.themeMode, defaultValue: 'system');
    return ThemeMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => ThemeMode.system,
    );
  }
  Future<void> setThemeMode(ThemeMode mode) => _box.put(HiveKeys.themeMode, mode.name);

  // Accent Color Mode
  AccentColorMode get accentColorMode {
    final String mode = _box.get(HiveKeys.accentColorMode, defaultValue: 'dynamic');
    return AccentColorMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => AccentColorMode.dynamic,
    );
  }
  Future<void> setAccentColorMode(AccentColorMode mode) => _box.put(HiveKeys.accentColorMode, mode.name);

  // Custom Accent Color
  Color get customAccentColor {
    final int colorValue = _box.get(
      HiveKeys.customAccentColor,
      defaultValue: Colors.blue.toARGB32(),
    );
    return Color(colorValue);
  }
  Future<void> setCustomAccentColor(Color color) => _box.put(HiveKeys.customAccentColor, color.toARGB32());

  // Swipe to Dismiss
  bool get swipeToDismiss => _box.get(HiveKeys.swipeToDismiss, defaultValue: true);
  Future<void> setSwipeToDismiss(bool value) => _box.put(HiveKeys.swipeToDismiss, value);

  // Minimum Duration
  int get minDuration => _box.get(HiveKeys.minDuration, defaultValue: 60);
  Future<void> setMinDuration(int seconds) => _box.put(HiveKeys.minDuration, seconds);

  // Haptic Feedback
  bool get enableHaptics => _box.get(HiveKeys.enableHaptics, defaultValue: true);
  Future<void> setEnableHaptics(bool value) => _box.put(HiveKeys.enableHaptics, value);

  // Haptic Force
  HapticForce get hapticForce {
    final String force = _box.get(HiveKeys.hapticForce, defaultValue: 'medium');
    return HapticForce.values.firstWhere(
      (e) => e.name == force,
      orElse: () => HapticForce.medium,
    );
  }
  Future<void> setHapticForce(HapticForce force) => _box.put(HiveKeys.hapticForce, force.name);

  // Playback Speed
  double get playbackSpeed => _box.get(HiveKeys.playbackSpeed, defaultValue: 1.0);
  Future<void> setPlaybackSpeed(double value) => _box.put(HiveKeys.playbackSpeed, value);

  // Reset Speed on New Track
  bool get resetSpeedOnNewTrack => _box.get(HiveKeys.resetSpeedOnNewTrack, defaultValue: true);
  Future<void> setResetSpeedOnNewTrack(bool value) => _box.put(HiveKeys.resetSpeedOnNewTrack, value);

  // Skip Silence
  bool get skipSilence => _box.get(HiveKeys.skipSilence, defaultValue: false);
  Future<void> setSkipSilence(bool value) => _box.put(HiveKeys.skipSilence, value);

  // Up Next Indicator
  bool get upNextIndicator => _box.get(HiveKeys.upNextIndicator, defaultValue: true);
  Future<void> setUpNextIndicator(bool value) => _box.put(HiveKeys.upNextIndicator, value);

  // Up Next Indicator Time
  int get upNextIndicatorTime => _box.get(HiveKeys.upNextIndicatorTime, defaultValue: 20);
  Future<void> setUpNextIndicatorTime(int seconds) => _box.put(HiveKeys.upNextIndicatorTime, seconds);

  // Appearance - AMOLED Mode
  bool get useAmoledMode => _box.get(HiveKeys.useAmoledMode, defaultValue: false);
  Future<void> setUseAmoledMode(bool value) => _box.put(HiveKeys.useAmoledMode, value);

  // Appearance - Artwork Shape
  ArtworkShape get artworkShape {
    final String shape = _box.get(HiveKeys.artworkShape, defaultValue: 'rounded');
    return ArtworkShape.values.firstWhere(
      (e) => e.name == shape,
      orElse: () => ArtworkShape.rounded,
    );
  }
  Future<void> setArtworkShape(ArtworkShape shape) => _box.put(HiveKeys.artworkShape, shape.name);

  // Appearance - Artwork Quality
  NixArtworkQuality get artworkQuality {
    final String quality = _box.get(HiveKeys.artworkQuality, defaultValue: 'high');
    return NixArtworkQuality.values.firstWhere(
      (e) => e.name == quality,
      orElse: () => NixArtworkQuality.high,
    );
  }
  Future<void> setArtworkQuality(NixArtworkQuality quality) => _box.put(HiveKeys.artworkQuality, quality.name);

  // Appearance - CD Artwork Style
  bool get useCdArtworkStyle => _box.get(HiveKeys.useCdArtworkStyle, defaultValue: true);
  Future<void> setUseCdArtworkStyle(bool value) => _box.put(HiveKeys.useCdArtworkStyle, value);

  // Appearance - Split CD
  bool get splitCdWhenHalfOpen => _box.get(HiveKeys.splitCdWhenHalfOpen, defaultValue: true);
  Future<void> setSplitCdWhenHalfOpen(bool value) => _box.put(HiveKeys.splitCdWhenHalfOpen, value);

  // Appearance - Rotate CD
  bool get rotateCdWhenPlaying => _box.get(HiveKeys.rotateCdWhenPlaying, defaultValue: true);
  Future<void> setRotateCdWhenPlaying(bool value) => _box.put(HiveKeys.rotateCdWhenPlaying, value);

  // Appearance - CD Rotation Speed
  double get cdRotationSpeed => (_box.get(HiveKeys.cdRotationSpeed) as num?)?.toDouble() ?? 20.0;
  Future<void> setCdRotationSpeed(double speed) => _box.put(HiveKeys.cdRotationSpeed, speed);

  // Appearance - Timer Gesture
  TimerGesture get timerGesture {
    final String gesture = _box.get(HiveKeys.timerGesture, defaultValue: 'longPress');
    return TimerGesture.values.firstWhere(
      (e) => e.name == gesture,
      orElse: () => TimerGesture.longPress,
    );
  }
  Future<void> setTimerGesture(TimerGesture gesture) => _box.put(HiveKeys.timerGesture, gesture.name);

  // Appearance - Swipe to Change Track
  bool get swipeToChangeTrack => _box.get(HiveKeys.swipeToChangeTrack, defaultValue: true);
  Future<void> setSwipeToChangeTrack(bool value) => _box.put(HiveKeys.swipeToChangeTrack, value);

  // Appearance - Track Swipe Action
  TrackSwipeAction get trackSwipeAction {
    final String action = _box.get(HiveKeys.trackSwipeAction, defaultValue: 'playPlayback');
    return TrackSwipeAction.values.firstWhere(
      (e) => e.name == action,
      orElse: () => TrackSwipeAction.playPlayback,
    );
  }
  Future<void> setTrackSwipeAction(TrackSwipeAction action) => _box.put(HiveKeys.trackSwipeAction, action.name);

  // Appearance - Miniplayer Shadow
  bool get showMiniplayerShadow => _box.get(HiveKeys.showMiniplayerShadow, defaultValue: true);
  Future<void> setShowMiniplayerShadow(bool value) => _box.put(HiveKeys.showMiniplayerShadow, value);

  // Appearance - Auto Scroll Queue
  bool get autoScrollQueue => _box.get(HiveKeys.autoScrollQueue, defaultValue: true);
  Future<void> setAutoScrollQueue(bool value) => _box.put(HiveKeys.autoScrollQueue, value);

  // Lyrics - Save Offline
  bool get saveLyricsOffline => _box.get(HiveKeys.saveLyricsOffline, defaultValue: true);
  Future<void> setSaveLyricsOffline(bool value) => _box.put(HiveKeys.saveLyricsOffline, value);

  // Appearance - SnackBar Position
  SnackBarPosition get snackbarPosition {
    final String position = _box.get(HiveKeys.snackbarPosition, defaultValue: 'bottom');
    return SnackBarPosition.values.firstWhere(
      (e) => e.name == position,
      orElse: () => SnackBarPosition.bottom,
    );
  }
  Future<void> setSnackbarPosition(SnackBarPosition position) => _box.put(HiveKeys.snackbarPosition, position.name);

  // Appearance - SnackBar Dismissible
  bool get snackbarSwipeToDismiss => _box.get(HiveKeys.snackbarSwipeToDismiss, defaultValue: true);
  Future<void> setSnackbarSwipeToDismiss(bool value) => _box.put(HiveKeys.snackbarSwipeToDismiss, value);

  // Search History
  List<String> get searchHistory {
    final List<dynamic> history = _box.get(HiveKeys.searchHistory, defaultValue: []);
    return history.cast<String>();
  }

  Future<void> addSearchQuery(String query) async {
    if (query.isEmpty) return;
    final List<String> history = searchHistory;
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) history.removeLast();
    await _box.put(HiveKeys.searchHistory, history);
  }

  Future<void> removeSearchQuery(String query) async {
    final List<String> history = searchHistory;
    history.remove(query);
    await _box.put(HiveKeys.searchHistory, history);
  }

  Future<void> clearSearchHistory() async {
    await _box.put(HiveKeys.searchHistory, []);
  }

  // Playback - Resume from Played Duration
  bool get resumeFromPlayedDuration => _box.get(HiveKeys.resumeFromPlayedDuration, defaultValue: true);
  Future<void> setResumeFromPlayedDuration(bool value) => _box.put(HiveKeys.resumeFromPlayedDuration, value);

  /// Clears the Hive settings box.
  Future<void> resetToDefaults() async {
    await _box.clear();
  }
}
