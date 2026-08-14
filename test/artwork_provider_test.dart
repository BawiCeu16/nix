import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/models/settings/artwork_quality.dart';
import 'package:nix/providers/artwork_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';

// Valid 1x1 PNG bytes
final Uint8List valid1x1Png = Uint8List.fromList([
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  10,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  0,
  1,
  0,
  0,
  5,
  0,
  1,
  13,
  10,
  45,
  180,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

class FakeAudioQuery extends Fake implements OnAudioQuery {
  final Map<int, Uint8List?> artworkResponses;

  FakeAudioQuery({this.artworkResponses = const {}});

  @override
  Future<Uint8List?> queryArtwork(
    int id,
    ArtworkType type, {
    ArtworkFormat? format,
    int? size,
    int? minId,
    int? quality,
  }) async {
    return artworkResponses[id];
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('nix_art_test');
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

  group('ArtworkProvider Parallel & Cache Tests', () {
    late ArtworkProvider provider;
    late FakeAudioQuery fakeQuery;

    setUp(() {
      fakeQuery = FakeAudioQuery(
        artworkResponses: {101: valid1x1Png, 102: valid1x1Png},
      );
      provider = ArtworkProvider(audioQuery: fakeQuery);
    });

    tearDown(() {
      provider.dispose();
    });

    test('getSync returns null on cache miss', () {
      final result = provider.getSync(
        999,
        ArtworkType.AUDIO,
        NixArtworkQuality.medium,
      );
      expect(result, isNull);
      expect(
        provider.isCached(999, ArtworkType.AUDIO, NixArtworkQuality.medium),
        isFalse,
      );
    });

    test(
      'getArtworkNotifier returns isolated ValueNotifier and fetches in background',
      () async {
        final notifier = provider.getArtworkNotifier(
          101,
          ArtworkType.AUDIO,
          NixArtworkQuality.medium,
        );

        expect(notifier, isNotNull);
        expect(
          notifier.value,
          isNull,
        ); // Initial before background query resolves

        // Allow background queue to process
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(notifier.value, equals(valid1x1Png));
        expect(
          provider.getSync(101, ArtworkType.AUDIO, NixArtworkQuality.medium),
          equals(valid1x1Png),
        );
        expect(
          provider.isCached(101, ArtworkType.AUDIO, NixArtworkQuality.medium),
          isTrue,
        );
      },
    );

    test('Multiple requests for same key share the same ValueNotifier', () {
      final notifier1 = provider.getArtworkNotifier(
        101,
        ArtworkType.AUDIO,
        NixArtworkQuality.high,
      );
      final notifier2 = provider.getArtworkNotifier(
        101,
        ArtworkType.AUDIO,
        NixArtworkQuality.high,
      );

      expect(identical(notifier1, notifier2), isTrue);
    });

    test('clearCache resets cache and updates active notifiers', () async {
      final notifier = provider.getArtworkNotifier(
        101,
        ArtworkType.AUDIO,
        NixArtworkQuality.medium,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.value, equals(valid1x1Png));

      bool changeNotified = false;
      provider.addListener(() {
        changeNotified = true;
      });

      provider.clearCache();

      expect(changeNotified, isTrue);
      expect(notifier.value, isNull);
      expect(
        provider.getSync(101, ArtworkType.AUDIO, NixArtworkQuality.medium),
        isNull,
      );
    });
  });

  group('NixArtwork Widget Rendering Tests', () {
    testWidgets('Renders synchronously without delay on cache hit', (
      tester,
    ) async {
      final fakeQuery = FakeAudioQuery(artworkResponses: {200: valid1x1Png});
      final provider = ArtworkProvider(audioQuery: fakeQuery);

      // Pre-warm the cache
      provider.getArtworkNotifier(
        200,
        ArtworkType.AUDIO,
        NixArtworkQuality.medium,
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NixArtwork(
                id: 200,
                type: ArtworkType.AUDIO,
                quality: NixArtworkQuality.medium,
                width: 48,
                height: 48,
              ),
            ),
          ),
        ),
      );

      // On the initial frame (0 extra ms pumped), Image.memory is already present!
      expect(find.byType(Image), findsOneWidget);

      provider.dispose();
    });

    testWidgets('Renders fallback on cache miss and transitions smoothly', (
      tester,
    ) async {
      final fakeQuery = FakeAudioQuery(artworkResponses: {300: valid1x1Png});
      final provider = ArtworkProvider(audioQuery: fakeQuery);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NixArtwork(
                id: 300,
                type: ArtworkType.AUDIO,
                quality: NixArtworkQuality.medium,
                width: 48,
                height: 48,
              ),
            ),
          ),
        ),
      );

      // Initially shows fallback icon
      expect(find.byKey(const ValueKey('fallback')), findsOneWidget);

      // Run async to resolve the background query
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      // Pump animation frames
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(Image), findsOneWidget);

      provider.dispose();
    });
  });
}
