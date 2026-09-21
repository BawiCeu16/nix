import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/core/constants.dart';

class FakeCurrentMusicProvider extends ChangeNotifier
    implements CurrentMusicProvider {
  bool _showMiniPlayer = false;

  @override
  bool get showMiniPlayer => _showMiniPlayer;

  void setShowMiniPlayer(bool value) {
    if (_showMiniPlayer != value) {
      _showMiniPlayer = value;
      notifyListeners();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('NixBottomSpacer Tests', () {
    late FakeCurrentMusicProvider musicProvider;

    setUp(() {
      musicProvider = FakeCurrentMusicProvider();
    });

    testWidgets('renders initial collapsed height when showMiniPlayer is false',
        (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<CurrentMusicProvider>.value(
          value: musicProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  NixBottomSpacer(),
                ],
              ),
            ),
          ),
        ),
      );

      // Expected collapsed height = 10.0 + 0 + 0 + 0 = 10.0
      const expectedHeight = 10.0 + NixConstants.kBottomPadding;
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.height, expectedHeight);
    });

    testWidgets('animates height smoothly when showMiniPlayer changes to true',
        (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<CurrentMusicProvider>.value(
          value: musicProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  NixBottomSpacer(),
                ],
              ),
            ),
          ),
        ),
      );

      const collapsedHeight = 10.0 + NixConstants.kBottomPadding;
      const expandedHeight = NixConstants.kMiniPlayerHeight +
          25.0 +
          NixConstants.kBottomPadding;

      // Initial state
      expect(tester.widget<SizedBox>(find.byType(SizedBox)).height, collapsedHeight);

      // Trigger showMiniPlayer = true
      musicProvider.setShowMiniPlayer(true);
      await tester.pump(); // Starts the animation

      // Height should not snap immediately
      await tester.pump(const Duration(milliseconds: 100));
      final midHeight = tester.widget<SizedBox>(find.byType(SizedBox)).height!;
      expect(midHeight, greaterThan(collapsedHeight));
      expect(midHeight, lessThan(expandedHeight));

      // Settle animation
      await tester.pumpAndSettle();
      expect(tester.widget<SizedBox>(find.byType(SizedBox)).height, expandedHeight);
    });

    testWidgets(
        'animates height smoothly down when MiniPlayer is dismissed (true -> false)',
        (tester) async {
      musicProvider.setShowMiniPlayer(true);

      await tester.pumpWidget(
        ChangeNotifierProvider<CurrentMusicProvider>.value(
          value: musicProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  NixBottomSpacer(),
                ],
              ),
            ),
          ),
        ),
      );

      const expandedHeight = NixConstants.kMiniPlayerHeight +
          25.0 +
          NixConstants.kBottomPadding;
      const collapsedHeight = 10.0 + NixConstants.kBottomPadding;

      expect(tester.widget<SizedBox>(find.byType(SizedBox)).height, expandedHeight);

      // MiniPlayer is dismissed!
      musicProvider.setShowMiniPlayer(false);
      await tester.pump(); // Frame 0 of dismiss animation

      // Should NOT have snapped to collapsed immediately
      await tester.pump(const Duration(milliseconds: 150));
      final intermediateHeight =
          tester.widget<SizedBox>(find.byType(SizedBox)).height!;
      expect(intermediateHeight, lessThan(expandedHeight));
      expect(intermediateHeight, greaterThan(collapsedHeight));

      // Finish animation
      await tester.pumpAndSettle();
      expect(tester.widget<SizedBox>(find.byType(SizedBox)).height, collapsedHeight);
    });

    testWidgets('works properly in sliver mode', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<CurrentMusicProvider>.value(
          value: musicProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  NixBottomSpacer.sliver(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SliverToBoxAdapter), findsOneWidget);
      expect(
        tester.widget<SizedBox>(find.byType(SizedBox)).height,
        10.0 + NixConstants.kBottomPadding,
      );

      // Expand
      musicProvider.setShowMiniPlayer(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        tester.widget<SizedBox>(find.byType(SizedBox)).height,
        greaterThan(10.0),
      );

      await tester.pumpAndSettle();
      expect(
        tester.widget<SizedBox>(find.byType(SizedBox)).height,
        NixConstants.kMiniPlayerHeight + 25.0 + NixConstants.kBottomPadding,
      );
    });

    testWidgets('supports custom appearDuration and dismissDuration',
        (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<CurrentMusicProvider>.value(
          value: musicProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  NixBottomSpacer(
                    appearDuration: Duration(milliseconds: 200),
                    dismissDuration: Duration(milliseconds: 400),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Appear animation should finish within 200ms
      musicProvider.setShowMiniPlayer(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 201));
      expect(
        tester.widget<SizedBox>(find.byType(SizedBox)).height,
        NixConstants.kMiniPlayerHeight + 25.0 + NixConstants.kBottomPadding,
      );

      // Dismiss animation at 200ms should still be in progress (since dismissDuration is 400ms)
      musicProvider.setShowMiniPlayer(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<SizedBox>(find.byType(SizedBox)).height,
        greaterThan(10.0 + NixConstants.kBottomPadding),
      );

      // Finish dismiss
      await tester.pump(const Duration(milliseconds: 201));
      expect(
        tester.widget<SizedBox>(find.byType(SizedBox)).height,
        10.0 + NixConstants.kBottomPadding,
      );
    });
  });
}

