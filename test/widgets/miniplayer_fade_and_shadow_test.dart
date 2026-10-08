import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nix/ui/miniplayer/widgets/miniplayer_presence_transition.dart';
import 'package:nix/ui/miniplayer/widgets/expressive_miniplayer_shadow.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MiniplayerPresenceTransition Tests', () {
    testWidgets('renders SizedBox.shrink when hasTrack is false initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniplayerPresenceTransition(
              hasTrack: false,
              child: Text('MiniplayerContent'),
            ),
          ),
        ),
      );

      // Should not be visible or mounted in active tree
      expect(find.text('MiniplayerContent'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('fades in smoothly when hasTrack becomes true', (tester) async {
      bool hasTrack = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MiniplayerPresenceTransition(
                  hasTrack: hasTrack,
                  child: const Text('MiniplayerContent'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('MiniplayerContent'), findsNothing);

      // Now set hasTrack = true
      hasTrack = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MiniplayerPresenceTransition(
                  hasTrack: hasTrack,
                  child: const Text('MiniplayerContent'),
                );
              },
            ),
          ),
        ),
      );

      // Initial frame of animation: mounted, opacity starts transitioning
      await tester.pump();
      expect(find.text('MiniplayerContent'), findsOneWidget);

      final initialOpacity = tester.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(initialOpacity, greaterThanOrEqualTo(0.0));
      expect(initialOpacity, lessThanOrEqualTo(1.0));

      // Advance halfway
      await tester.pump(const Duration(milliseconds: 150));
      final midOpacity = tester.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(midOpacity, greaterThan(initialOpacity));

      // Complete transition
      await tester.pump(const Duration(milliseconds: 250));
      final finalOpacity = tester.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(finalOpacity, equals(1.0));
    });

    testWidgets('fades out smoothly when hasTrack becomes false and unmounts to SizedBox.shrink', (tester) async {
      bool hasTrack = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MiniplayerPresenceTransition(
                  hasTrack: hasTrack,
                  child: const Text('MiniplayerContent'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('MiniplayerContent'), findsOneWidget);

      // Switch hasTrack to false
      hasTrack = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MiniplayerPresenceTransition(
                  hasTrack: hasTrack,
                  child: const Text('MiniplayerContent'),
                );
              },
            ),
          ),
        ),
      );

      // Should still be mounted and fading out
      await tester.pump();
      expect(find.text('MiniplayerContent'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('MiniplayerContent'), findsOneWidget);
      final fadeOpacity = tester.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(fadeOpacity, lessThan(1.0));
      expect(fadeOpacity, greaterThan(0.0));

      // Complete reverse fade out
      await tester.pump(const Duration(milliseconds: 200));
      // Once reverse completes, unmounts to SizedBox.shrink
      expect(find.text('MiniplayerContent'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });

  group('ExpressiveMiniplayerShadow Tests', () {
    testWidgets('returns SizedBox.shrink when isVisible is false initially', (tester) async {
      final sheetAnim = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 300),
        value: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpressiveMiniplayerShadow(
              sheetAnimation: sheetAnim,
              isVisible: false,
              shadowOpacity: 1.0,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);

      sheetAnim.dispose();
    });

    testWidgets('animates fade in when isVisible becomes true and fades out when false', (tester) async {
      final sheetAnim = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 300),
        value: 0.0,
      );

      bool isVisible = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ExpressiveMiniplayerShadow(
                  sheetAnimation: sheetAnim,
                  isVisible: isVisible,
                  shadowOpacity: 0.8,
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsNothing);

      // Make visible
      isVisible = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ExpressiveMiniplayerShadow(
                  sheetAnimation: sheetAnim,
                  isVisible: isVisible,
                  shadowOpacity: 0.8,
                );
              },
            ),
          ),
        ),
      );

      // Animate fade-in
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(Container), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(Container), findsOneWidget);

      // Make invisible again
      isVisible = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ExpressiveMiniplayerShadow(
                  sheetAnimation: sheetAnim,
                  isVisible: isVisible,
                  shadowOpacity: 0.8,
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Container), findsOneWidget);

      // Finish fade-out
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(Container), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);

      sheetAnim.dispose();
    });
  });
}
