import 'package:flutter/material.dart';
import 'package:nix/models/settings/artwork_quality.dart';
import 'package:nix/models/settings/timer_gesture.dart';
import 'package:nix/services/settings_repository.dart';

enum AccentColorMode { dynamic, device, custom }

enum ArtworkShape { rounded, circle }

enum NavbarStyle { floating, standard }

enum SnackBarPosition { top, bottom }

enum TrackSwipeAction { none, playPlayback }

enum HapticForce { light, medium, heavy }

/// Manages app-wide settings state and delegates persistence to [SettingsRepository].
class SettingsProvider with ChangeNotifier {
  final SettingsRepository _repo = SettingsRepository();

  // Auto Play
  bool get autoPlay => _repo.autoPlay;
  void setAutoPlay(bool value) {
    _repo.setAutoPlay(value).then((_) => notifyListeners());
  }

  // Theme Mode
  ThemeMode get themeMode => _repo.themeMode;
  void setThemeMode(ThemeMode mode) {
    _repo.setThemeMode(mode).then((_) => notifyListeners());
  }

  // Accent Color Mode
  AccentColorMode get accentColorMode => _repo.accentColorMode;
  void setAccentColorMode(AccentColorMode mode) {
    _repo.setAccentColorMode(mode).then((_) => notifyListeners());
  }

  // Custom Accent Color
  Color get customAccentColor => _repo.customAccentColor;
  void setCustomAccentColor(Color color) {
    _repo.setCustomAccentColor(color).then((_) => notifyListeners());
  }

  // Swipe to Dismiss
  bool get swipeToDismiss => _repo.swipeToDismiss;
  void setSwipeToDismiss(bool value) {
    _repo.setSwipeToDismiss(value).then((_) => notifyListeners());
  }

  // Minimum Duration
  int get minDuration => _repo.minDuration;
  void setMinDuration(int seconds) {
    _repo.setMinDuration(seconds).then((_) => notifyListeners());
  }

  // Haptic Feedback
  bool get enableHaptics => _repo.enableHaptics;
  void setEnableHaptics(bool value) {
    _repo.setEnableHaptics(value).then((_) => notifyListeners());
  }

  // Haptic Force
  HapticForce get hapticForce => _repo.hapticForce;
  void setHapticForce(HapticForce force) {
    _repo.setHapticForce(force).then((_) => notifyListeners());
  }

  // Playback Speed
  double get playbackSpeed => _repo.playbackSpeed;
  void setPlaybackSpeed(double value) {
    _repo.setPlaybackSpeed(value).then((_) => notifyListeners());
  }

  // Reset Speed on New Track
  bool get resetSpeedOnNewTrack => _repo.resetSpeedOnNewTrack;
  void setResetSpeedOnNewTrack(bool value) {
    _repo.setResetSpeedOnNewTrack(value).then((_) => notifyListeners());
  }

  // Skip Silence
  bool get skipSilence => _repo.skipSilence;
  void setSkipSilence(bool value) {
    _repo.setSkipSilence(value).then((_) => notifyListeners());
  }

  // Up Next Indicator
  bool get upNextIndicator => _repo.upNextIndicator;
  void setUpNextIndicator(bool value) {
    _repo.setUpNextIndicator(value).then((_) => notifyListeners());
  }

  // Up Next Indicator Time
  int get upNextIndicatorTime => _repo.upNextIndicatorTime;
  void setUpNextIndicatorTime(int seconds) {
    _repo.setUpNextIndicatorTime(seconds).then((_) => notifyListeners());
  }

  // Appearance - AMOLED Mode
  bool get useAmoledMode => _repo.useAmoledMode;
  void setUseAmoledMode(bool value) {
    _repo.setUseAmoledMode(value).then((_) => notifyListeners());
  }

  // Appearance - Artwork Shape
  ArtworkShape get artworkShape => _repo.artworkShape;
  void setArtworkShape(ArtworkShape shape) {
    _repo.setArtworkShape(shape).then((_) => notifyListeners());
  }

  // Appearance - Artwork Quality
  NixArtworkQuality get artworkQuality => _repo.artworkQuality;
  void setArtworkQuality(NixArtworkQuality quality) {
    _repo.setArtworkQuality(quality).then((_) => notifyListeners());
  }

  // Appearance - CD Artwork Style
  bool get useCdArtworkStyle => _repo.useCdArtworkStyle;
  void setUseCdArtworkStyle(bool value) {
    _repo.setUseCdArtworkStyle(value).then((_) => notifyListeners());
  }

  // Appearance - Split CD
  bool get splitCdWhenHalfOpen => _repo.splitCdWhenHalfOpen;
  void setSplitCdWhenHalfOpen(bool value) {
    _repo.setSplitCdWhenHalfOpen(value).then((_) => notifyListeners());
  }

  // Appearance - Rotate CD
  bool get rotateCdWhenPlaying => _repo.rotateCdWhenPlaying;
  void setRotateCdWhenPlaying(bool value) {
    _repo.setRotateCdWhenPlaying(value).then((_) => notifyListeners());
  }

  // Appearance - CD Rotation Speed
  double get cdRotationSpeed => _repo.cdRotationSpeed;
  void setCdRotationSpeed(double speed) {
    _repo.setCdRotationSpeed(speed).then((_) => notifyListeners());
  }

  // Appearance - Timer Gesture
  TimerGesture get timerGesture => _repo.timerGesture;
  void setTimerGesture(TimerGesture gesture) {
    _repo.setTimerGesture(gesture).then((_) => notifyListeners());
  }

  // Appearance - Swipe to Change Track
  bool get swipeToChangeTrack => _repo.swipeToChangeTrack;
  void setSwipeToChangeTrack(bool value) {
    _repo.setSwipeToChangeTrack(value).then((_) => notifyListeners());
  }

  // Appearance - Fast Swipe Artwork
  bool get fastSwipeArtwork => _repo.fastSwipeArtwork;
  void setFastSwipeArtwork(bool value) {
    _repo.setFastSwipeArtwork(value).then((_) => notifyListeners());
  }

  // Appearance - Track Swipe Action
  TrackSwipeAction get trackSwipeAction => _repo.trackSwipeAction;
  void setTrackSwipeAction(TrackSwipeAction action) {
    _repo.setTrackSwipeAction(action).then((_) => notifyListeners());
  }

  // Appearance - Miniplayer Shadow
  bool get showMiniplayerShadow => _repo.showMiniplayerShadow;
  void setShowMiniplayerShadow(bool value) {
    _repo.setShowMiniplayerShadow(value).then((_) => notifyListeners());
  }

  // Appearance - Auto Scroll Queue
  bool get autoScrollQueue => _repo.autoScrollQueue;
  void setAutoScrollQueue(bool value) {
    _repo.setAutoScrollQueue(value).then((_) => notifyListeners());
  }

  // Lyrics - Save Offline
  bool get saveLyricsOffline => _repo.saveLyricsOffline;
  void setSaveLyricsOffline(bool value) {
    _repo.setSaveLyricsOffline(value).then((_) => notifyListeners());
  }

  // Appearance - SnackBar Position
  SnackBarPosition get snackbarPosition => _repo.snackbarPosition;
  void setSnackbarPosition(SnackBarPosition position) {
    _repo.setSnackbarPosition(position).then((_) => notifyListeners());
  }

  // Appearance - SnackBar Dismissible
  bool get snackbarSwipeToDismiss => _repo.snackbarSwipeToDismiss;
  void setSnackbarSwipeToDismiss(bool value) {
    _repo.setSnackbarSwipeToDismiss(value).then((_) => notifyListeners());
  }

  // Search History
  List<String> get searchHistory => _repo.searchHistory;

  void addSearchQuery(String query) {
    _repo.addSearchQuery(query).then((_) => notifyListeners());
  }

  void removeSearchQuery(String query) {
    _repo.removeSearchQuery(query).then((_) => notifyListeners());
  }

  void clearSearchHistory() {
    _repo.clearSearchHistory().then((_) => notifyListeners());
  }

  // Playback - Resume from Played Duration
  bool get resumeFromPlayedDuration => _repo.resumeFromPlayedDuration;
  void setResumeFromPlayedDuration(bool value) {
    _repo.setResumeFromPlayedDuration(value).then((_) => notifyListeners());
  }

  /// Resets ALL settings to factory defaults.
  void resetToDefaults() {
    _repo.resetToDefaults().then((_) => notifyListeners());
  }
}
