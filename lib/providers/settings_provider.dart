import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/models/settings/artwork_quality.dart';
import 'package:nix/models/settings/timer_gesture.dart';

enum AccentColorMode { dynamic, device, custom }

enum ArtworkShape { rounded, circle }

enum NavbarStyle { floating, standard }

enum SnackBarPosition { top, bottom }

enum TrackSwipeAction { none, playPlayback }

enum HapticForce { light, medium, heavy }

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

  // Haptic Force
  /// The intensity of the haptic feedback.
  HapticForce get hapticForce {
    final String force = _box.get(HiveKeys.hapticForce, defaultValue: 'medium');
    return HapticForce.values.firstWhere(
      (e) => e.name == force,
      orElse: () => HapticForce.medium,
    );
  }

  void setHapticForce(HapticForce force) {
    _box.put(HiveKeys.hapticForce, force.name);
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

  // Up Next Indicator
  /// Whether to show the Up Next indicator near the end of a track.
  bool get upNextIndicator =>
      _box.get(HiveKeys.upNextIndicator, defaultValue: true);

  void setUpNextIndicator(bool value) {
    _box.put(HiveKeys.upNextIndicator, value);
    notifyListeners();
  }

  // Up Next Indicator Time
  /// Time in seconds before track end to show the indicator.
  int get upNextIndicatorTime =>
      _box.get(HiveKeys.upNextIndicatorTime, defaultValue: 20);

  void setUpNextIndicatorTime(int seconds) {
    _box.put(HiveKeys.upNextIndicatorTime, seconds);
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

  // Appearance - CD Artwork Style
  /// Whether to display albums using a realistic CD jewel case widget
  bool get useCdArtworkStyle =>
      _box.get(HiveKeys.useCdArtworkStyle, defaultValue: true);

  void setUseCdArtworkStyle(bool value) {
    _box.put(HiveKeys.useCdArtworkStyle, value);
    notifyListeners();
  }

  // Appearance - Split CD when Half Open
  /// Whether the CD cover and disc split evenly from the center horizontally
  bool get splitCdWhenHalfOpen =>
      _box.get(HiveKeys.splitCdWhenHalfOpen, defaultValue: true);

  void setSplitCdWhenHalfOpen(bool value) {
    _box.put(HiveKeys.splitCdWhenHalfOpen, value);
    notifyListeners();
  }

  // Appearance - Rotate CD when Playing
  /// Whether the CD disc rotates physically when a track from the album is playing
  bool get rotateCdWhenPlaying =>
      _box.get(HiveKeys.rotateCdWhenPlaying, defaultValue: true);

  void setRotateCdWhenPlaying(bool value) {
    _box.put(HiveKeys.rotateCdWhenPlaying, value);
    notifyListeners();
  }

  // Appearance - CD Rotation Speed
  /// The local multiplier for the continuous rotation of active CD artworks
  double get cdRotationSpeed =>
      (_box.get(HiveKeys.cdRotationSpeed) as num?)?.toDouble() ?? 20.0;

  void setCdRotationSpeed(double speed) {
    _box.put(HiveKeys.cdRotationSpeed, speed);
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

  // Appearance - Swipe to Change Track
  /// Whether horizontal swipes on artwork change the track.
  bool get swipeToChangeTrack =>
      _box.get(HiveKeys.swipeToChangeTrack, defaultValue: true);

  void setSwipeToChangeTrack(bool value) {
    _box.put(HiveKeys.swipeToChangeTrack, value);
    notifyListeners();
  }

  // Appearance - Track Swipe Action
  /// The global action for track tile swipes.
  TrackSwipeAction get trackSwipeAction {
    final String action = _box.get(
      HiveKeys.trackSwipeAction,
      defaultValue: 'playPlayback',
    );
    return TrackSwipeAction.values.firstWhere(
      (e) => e.name == action,
      orElse: () => TrackSwipeAction.playPlayback,
    );
  }

  void setTrackSwipeAction(TrackSwipeAction action) {
    _box.put(HiveKeys.trackSwipeAction, action.name);
    notifyListeners();
  }

  // Appearance - Miniplayer Shadow
  /// Whether to show the dynamic shadow on the miniplayer.
  bool get showMiniplayerShadow =>
      _box.get(HiveKeys.showMiniplayerShadow, defaultValue: true);

  void setShowMiniplayerShadow(bool value) {
    _box.put(HiveKeys.showMiniplayerShadow, value);
    notifyListeners();
  }

  // Appearance - Auto Scroll Queue
  /// Whether to automatically scroll the queue to the currently playing track.
  bool get autoScrollQueue =>
      _box.get(HiveKeys.autoScrollQueue, defaultValue: true);

  void setAutoScrollQueue(bool value) {
    _box.put(HiveKeys.autoScrollQueue, value);
    notifyListeners();
  }

  // Lyrics - Save Offline
  /// Whether to save lyrics for offline use.
  bool get saveLyricsOffline =>
      _box.get(HiveKeys.saveLyricsOffline, defaultValue: true);

  void setSaveLyricsOffline(bool value) {
    _box.put(HiveKeys.saveLyricsOffline, value);
    notifyListeners();
  }

  // Appearance - SnackBar Position
  /// The global position for all snackbars.
  SnackBarPosition get snackbarPosition {
    final String position = _box.get(
      HiveKeys.snackbarPosition,
      defaultValue: 'bottom',
    );
    return SnackBarPosition.values.firstWhere(
      (e) => e.name == position,
      orElse: () => SnackBarPosition.bottom,
    );
  }

  void setSnackbarPosition(SnackBarPosition position) {
    _box.put(HiveKeys.snackbarPosition, position.name);
    notifyListeners();
  }

  // Appearance - SnackBar Dismissible
  /// Whether snackbars can be swiped away by the user.
  bool get snackbarSwipeToDismiss =>
      _box.get(HiveKeys.snackbarSwipeToDismiss, defaultValue: true);

  void setSnackbarSwipeToDismiss(bool value) {
    _box.put(HiveKeys.snackbarSwipeToDismiss, value);
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

  // Playback - Resume from Played Duration
  /// Whether to resume tracks from their last saved position.
  bool get resumeFromPlayedDuration =>
      _box.get(HiveKeys.resumeFromPlayedDuration, defaultValue: true);

  void setResumeFromPlayedDuration(bool value) {
    _box.put(HiveKeys.resumeFromPlayedDuration, value);
    notifyListeners();
  }

  /// Resets ALL settings to their factory defaults by clearing the Hive box.
  /// Each getter's `defaultValue` will take effect on the next read.
  void resetToDefaults() {
    _box.clear();
    notifyListeners();
  }
}
