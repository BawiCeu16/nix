import 'package:audio_service/audio_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/providers/current_music_provider.dart';

/// Encapsulates the results of asynchronous application bootstrap.
class AppInitResult {
  final CurrentMusicProvider audioHandler;
  final bool hasCompletedOnboarding;

  const AppInitResult({
    required this.audioHandler,
    required this.hasCompletedOnboarding,
  });
}

/// Handles low-level startup tasks including Hive storage and AudioService initialization.
class AppInitializer {
  const AppInitializer._();

  /// Initializes persistent storage and background audio services.
  static Future<AppInitResult> initialize() async {
    await Hive.initFlutter();

    // Open all Hive boxes in parallel to speed up initialization
    await Future.wait([
      Hive.openBox(HiveKeys.settingsBox),
      Hive.openBox<int>(HiveKeys.colorCacheBox),
      Hive.openBox(HiveKeys.lyricsBox),
      Hive.openBox<int>(HiveKeys.trackPositionsBox),
      Hive.openBox<int>(HiveKeys.favoritesBox),
      Hive.openBox<String>(HiveKeys.playlistsBox),
      Hive.openBox<int>(HiveKeys.playHistoryBox),
      Hive.openBox<int>(HiveKeys.playCountsBox),
      Hive.openBox<int>(HiveKeys.playDurationsBox),
    ]);

    final bool hasCompletedOnboarding = Hive.box(
      HiveKeys.settingsBox,
    ).get(HiveKeys.onboarding, defaultValue: false);

    final CurrentMusicProvider audioHandler = await AudioService.init(
      builder: () => CurrentMusicProvider(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.c.nix.channel.audio',
        androidNotificationChannelName: 'nix Audio playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_notification',
      ),
    );

    await audioHandler.init();

    return AppInitResult(
      audioHandler: audioHandler,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }
}
