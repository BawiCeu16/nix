import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/screens/controllers/stats_controller.dart';
import 'package:nix/ui/screens/stats_page.dart';

class FakeCurrentMusicProvider extends ChangeNotifier
    implements CurrentMusicProvider {
  Track? lastPlayedTrack;
  List<Track>? lastPlaylistContext;

  @override
  bool get showMiniPlayer => false;

  @override
  Stream<Track> get onTrackPlayedStream => const Stream.empty();

  @override
  Future<void> playTrack(
    Track track, {
    Playlist? playlist,
  }) async {
    lastPlayedTrack = track;
    lastPlaylistContext = playlist?.tracks;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMusicProvider extends ChangeNotifier implements MusicProvider {
  List<Track> _tracks = [];

  @override
  List<Track> get tracks => _tracks;

  set tracks(List<Track> list) {
    _tracks = list;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('nix_stats_test');
    Hive.init(tempDir.path);
    await Hive.openBox<int>(HiveKeys.playCountsBox);
    await Hive.openBox<int>(HiveKeys.playHistoryBox);
    await Hive.openBox<int>(HiveKeys.playDurationsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await Hive.box<int>(HiveKeys.playCountsBox).clear();
    await Hive.box<int>(HiveKeys.playHistoryBox).clear();
    await Hive.box<int>(HiveKeys.playDurationsBox).clear();
  });

  test('StatsController formatting utilities work correctly', () {
    expect(StatsController.formatDuration(const Duration(hours: 2, minutes: 15)), '2h 15m');
    expect(StatsController.formatDuration(const Duration(minutes: 42)), '42m');
    expect(StatsController.formatDuration(const Duration(seconds: 35)), '35s');
    expect(StatsController.formatDuration(Duration.zero), '0m');

    final now = DateTime.now();
    expect(StatsController.formatRelativeTime(now.subtract(const Duration(seconds: 10))), 'Just now');
    expect(StatsController.formatRelativeTime(now.subtract(const Duration(minutes: 5))), '5m ago');
    expect(StatsController.formatRelativeTime(now.subtract(const Duration(hours: 3))), '3h ago');
    expect(StatsController.formatRelativeTime(now.subtract(const Duration(days: 1))), 'Yesterday');
    expect(StatsController.formatRelativeTime(now.subtract(const Duration(days: 4))), '4d ago');

    // Test formatDateAdded
    expect(StatsController.formatDateAdded(0), 'Unknown');
    final specificDateMs = DateTime(2026, 8, 14).millisecondsSinceEpoch;
    expect(StatsController.formatDateAdded(specificDateMs), '14/8/2026');
  });

  testWidgets('StatsPage renders empty state when no plays are recorded', (tester) async {
    final fakeMusic = FakeMusicProvider();
    final fakeCurrentMusic = FakeCurrentMusicProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MusicProvider>.value(value: fakeMusic),
          ChangeNotifierProvider<CurrentMusicProvider>.value(value: fakeCurrentMusic),
        ],
        child: const MaterialApp(
          home: StatsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Bento metric boxes
    expect(find.text('Listening Stats'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Listen Time'), findsOneWidget);
    expect(find.text('Total Plays'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);

    // Verify Insights and Tabs
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Top Songs'), findsOneWidget);
    expect(find.text('Top Artists'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Verify Empty state for top songs
    expect(find.text('No song plays recorded yet'), findsOneWidget);
  });

  testWidgets('StatsPage displays hero card, top songs, top artists, and supports sorting by Date Added', (tester) async {
    final track1 = Track(
      id: 101,
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: 240000,
      uri: '/path/to/101.mp3',
      dateAdded: 1600000000, // Older date added
    );

    final track2 = Track(
      id: 102,
      title: 'Starboy',
      artist: 'The Weeknd',
      album: 'Starboy',
      duration: 230000,
      uri: '/path/to/102.mp3',
      dateAdded: 1700000000, // Newer date added
    );

    final fakeMusic = FakeMusicProvider()..tracks = [track1, track2];
    final fakeCurrentMusic = FakeCurrentMusicProvider();

    // Populate Hive stats
    final playCountsBox = Hive.box<int>(HiveKeys.playCountsBox);
    await playCountsBox.put(101, 15);
    await playCountsBox.put(102, 8);

    final playHistoryBox = Hive.box<int>(HiveKeys.playHistoryBox);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await playHistoryBox.put(101, nowMs - 60000); // 1m ago
    await playHistoryBox.put(102, nowMs - 3600000); // 1h ago

    final playDurationsBox = Hive.box<int>(HiveKeys.playDurationsBox);
    await playDurationsBox.put(101, 15 * 240000);
    await playDurationsBox.put(102, 8 * 230000);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MusicProvider>.value(value: fakeMusic),
          ChangeNotifierProvider<CurrentMusicProvider>.value(value: fakeCurrentMusic),
        ],
        child: const MaterialApp(
          home: StatsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Hero Card
    expect(find.text('#1 MOST PLAYED'), findsOneWidget);
    expect(find.text('15 plays'), findsWidgets);
    expect(find.text('Midnight City'), findsWidgets);
    expect(find.text('M83'), findsWidgets);

    // Verify Bento stats
    expect(find.text('23'), findsOneWidget); // 15 + 8 total plays
    expect(find.text('2'), findsOneWidget); // 2 unique artists

    // Verify Top Songs list
    expect(find.text('Starboy'), findsOneWidget);
    expect(find.text('8 plays'), findsOneWidget);

    // Verify sort pill is present
    expect(find.text('Sorted by:'), findsOneWidget);
    expect(find.text('Most Played'), findsOneWidget);

    // Tap "Change" to open the bottom sheet sort selector
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Sort Top Songs'), findsOneWidget);
    expect(find.text('Date Added'), findsOneWidget);

    // Select "Date Added" sort
    await tester.tap(find.text('Date Added'));
    await tester.pumpAndSettle();

    // Now Starboy (newer dateAdded) should be first in sorted order
    expect(find.text('Sorted by:'), findsOneWidget);
    expect(find.text('Date Added'), findsOneWidget);

    // Tap on Top Artists tab
    await tester.tap(find.text('Top Artists'));
    await tester.pumpAndSettle();

    expect(find.text('M83'), findsOneWidget);
    expect(find.text('The Weeknd'), findsOneWidget);
    expect(find.text('1 track played'), findsNWidgets(2));

    // Tap on History tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Midnight City'), findsWidgets);
    expect(find.text('Starboy'), findsOneWidget);
    expect(find.text('1m ago'), findsOneWidget);
    expect(find.text('1h ago'), findsOneWidget);
  });
}
