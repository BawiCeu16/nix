import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/miniplayer/models/animation_data.dart';
import 'package:nix/ui/miniplayer/widgets/track_info.dart';
import 'package:provider/provider.dart';

class FakeCurrentMusicProvider extends ChangeNotifier
    implements CurrentMusicProvider {
  Track? _fakeTrack;

  @override
  Track? get currentTrack => _fakeTrack;

  set currentTrack(Track? t) {
    _fakeTrack = t;
    notifyListeners();
  }

  @override
  Track? get nextTrack => null;

  @override
  Track? get previousTrack => null;

  @override
  bool get showMiniPlayer => _fakeTrack != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('nix_track_info_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveKeys.settingsBox);
    await Hive.openBox<int>(HiveKeys.colorCacheBox);
    await Hive.openBox(HiveKeys.lyricsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  PlayerAnimationData createAnimationData({
    double progress = 1.0,
    double clampedProgress = 1.0,
    double queueProgress = 0.0,
  }) {
    return PlayerAnimationData(
      progress: progress,
      clampedProgress: clampedProgress,
      inverseProgress: 1.0 - progress,
      inverseClampedProgress: 1.0 - clampedProgress,
      reverseProgress: 0.0,
      reverseClampedProgress: 0.0,
      bounceProgress: clampedProgress,
      bounceClampedProgress: clampedProgress,
      queueProgress: queueProgress,
      queueClampedProgress: queueProgress,
      topRowOpacity: 1.0,
      opacity: 1.0,
      fastOpacity: 1.0,
      bottomOffset: 0.0,
      panelHeight: 800.0,
      borderRadius: BorderRadius.circular(16),
    );
  }

  testWidgets('Long pressing title in NowPlaying section copies track title to clipboard', (tester) async {
    final settingsProvider = SettingsProvider();
    final currentMusicProvider = FakeCurrentMusicProvider();
    final musicProvider = MusicProvider();

    final testTrack = Track(
      id: 1,
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      album: 'A Night at the Opera',
      duration: 354000,
      uri: '/path/to/song.mp3',
      dateAdded: 0,
    );

    currentMusicProvider.currentTrack = testTrack;
    final zeroAnim = AlwaysStoppedAnimation<double>(0.0);

    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (message) async {
      if (message.method == 'Clipboard.setData') {
        final args = message.arguments as Map?;
        copiedText = args?['text'] as String?;
      }
      return null;
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider<CurrentMusicProvider>.value(
            value: currentMusicProvider,
          ),
          ChangeNotifierProvider.value(value: musicProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TrackInfo(
              sAnim: zeroAnim,
              sMaxOffset: 100,
              stParallax: 1.5,
              maxOffset: 400,
              topInset: 20,
              bounceUp: false,
              bounceDown: false,
              screenSize: const Size(400, 800),
              data: createAnimationData(
                progress: 1.0,
                clampedProgress: 1.0,
                queueProgress: 0.0,
              ),
              lyricsAnim: zeroAnim,
              onToggleLyrics: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Bohemian Rhapsody'), findsOneWidget);

    // Long press on title in NowPlaying
    await tester.longPress(find.text('Bohemian Rhapsody'));
    await tester.pump();

    expect(copiedText, equals('Bohemian Rhapsody'));

    // Wait for the snackbar dismiss timer
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('Long pressing title in MiniPlayer section does NOT copy title', (tester) async {
    final settingsProvider = SettingsProvider();
    final currentMusicProvider = FakeCurrentMusicProvider();
    final musicProvider = MusicProvider();

    final testTrack = Track(
      id: 2,
      title: 'Hotel California',
      artist: 'Eagles',
      album: 'Hotel California',
      duration: 390000,
      uri: '/path/to/song2.mp3',
      dateAdded: 0,
    );

    currentMusicProvider.currentTrack = testTrack;
    final zeroAnim = AlwaysStoppedAnimation<double>(0.0);

    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (message) async {
      if (message.method == 'Clipboard.setData') {
        final args = message.arguments as Map?;
        copiedText = args?['text'] as String?;
      }
      return null;
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider<CurrentMusicProvider>.value(
            value: currentMusicProvider,
          ),
          ChangeNotifierProvider.value(value: musicProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TrackInfo(
              sAnim: zeroAnim,
              sMaxOffset: 100,
              stParallax: 1.5,
              maxOffset: 400,
              topInset: 20,
              bounceUp: false,
              bounceDown: false,
              screenSize: const Size(400, 800),
              data: createAnimationData(
                progress: 0.0,
                clampedProgress: 0.0,
                queueProgress: 0.0,
              ),
              lyricsAnim: zeroAnim,
              onToggleLyrics: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hotel California'), findsOneWidget);

    // Long press on title in MiniPlayer mode
    await tester.longPress(find.text('Hotel California'));
    await tester.pump();

    expect(copiedText, isNull);
  });

  testWidgets('Long pressing title in Queue section does NOT copy title', (tester) async {
    final settingsProvider = SettingsProvider();
    final currentMusicProvider = FakeCurrentMusicProvider();
    final musicProvider = MusicProvider();

    final testTrack = Track(
      id: 3,
      title: 'Stairway to Heaven',
      artist: 'Led Zeppelin',
      album: 'Led Zeppelin IV',
      duration: 482000,
      uri: '/path/to/song3.mp3',
      dateAdded: 0,
    );

    currentMusicProvider.currentTrack = testTrack;
    final zeroAnim = AlwaysStoppedAnimation<double>(0.0);

    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (message) async {
      if (message.method == 'Clipboard.setData') {
        final args = message.arguments as Map?;
        copiedText = args?['text'] as String?;
      }
      return null;
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider<CurrentMusicProvider>.value(
            value: currentMusicProvider,
          ),
          ChangeNotifierProvider.value(value: musicProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TrackInfo(
              sAnim: zeroAnim,
              sMaxOffset: 100,
              stParallax: 1.5,
              maxOffset: 400,
              topInset: 20,
              bounceUp: false,
              bounceDown: false,
              screenSize: const Size(400, 800),
              data: createAnimationData(
                progress: 2.0,
                clampedProgress: 1.0,
                queueProgress: 1.0,
              ),
              lyricsAnim: zeroAnim,
              onToggleLyrics: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Stairway to Heaven'), findsOneWidget);

    // Long press on title in Queue mode
    await tester.longPress(find.text('Stairway to Heaven'));
    await tester.pump();

    expect(copiedText, isNull);
  });
}
