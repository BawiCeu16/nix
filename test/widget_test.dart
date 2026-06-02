import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/providers/sleep_timer_provider.dart';
import 'package:nix/providers/artwork_provider.dart';
import 'package:nix/providers/will_pop_provider.dart';
import 'package:nix/main.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('nix_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveKeys.settingsBox);
    await Hive.openBox<int>(HiveKeys.colorCacheBox);
    await Hive.openBox(HiveKeys.lyricsBox);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => CurrentMusicProvider()),
          ChangeNotifierProvider(
            create: (context) => MusicProvider()
              ..init(currentMusic: context.read<CurrentMusicProvider>()),
          ),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => SleepTimerProvider()),
          ChangeNotifierProvider(create: (_) => ArtworkProvider()),
          Provider(create: (_) => WillPopProvider()),
        ],
        child: const NixApp(hasCompletedOnboarding: false),
      ),
    );

    // Verify that the app builds successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
