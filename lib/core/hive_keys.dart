/// Centralised Hive box names and key constants.
///
/// Using a single source of truth for all storage keys prevents typos and
/// makes it easy to audit everything written to persistent storage.
abstract final class HiveKeys {
  // ── Box names ──────────────────────────────────────────────────────────────
  static const String settingsBox = 'settings';
  static const String playlistsBox = 'playlists';
  static const String favoritesBox = 'favorites';
  static const String playHistoryBox = 'play_history';
  static const String playCountsBox = 'play_counts';

  // ── Settings keys ──────────────────────────────────────────────────────────
  static const String themeMode = 'themeMode';
  static const String accentColorMode = 'accentColorMode';
  static const String customAccentColor = 'customAccentColor';
  static const String autoPlay = 'autoPlay';
  static const String swipeToDismiss = 'swipeToDismiss';
  static const String minDuration = 'minDuration';
  static const String enableHaptics = 'enableHaptics';
  static const String playbackSpeed = 'playbackSpeed';
  static const String resetSpeedOnNewTrack = 'resetSpeedOnNewTrack';
  static const String skipSilence = 'skipSilence';
  static const String useAmoledMode = 'useAmoledMode';
  static const String artworkShape = 'artworkShape';
  static const String onboarding = 'hasCompletedOnboarding';

  // ── User keys ──────────────────────────────────────────────────────────────
  static const String username = 'username';
  static const String avatarIndex = 'avatarIndex';
  static const String searchHistory = 'searchHistory';
}
