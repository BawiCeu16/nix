import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nix/ui/miniplayer/widgets/bouncing_skip_button.dart';

void main() {
  group('BouncingSkipButton', () {
    testWidgets('Next button bounces right and returns to initial position', (
      tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BouncingSkipButton.next(
                icon: FlutterRemix.skip_forward_fill,
                color: Colors.white,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(BouncingSkipButton);
      expect(buttonFinder, findsOneWidget);

      final translateFinder = find
          .descendant(of: buttonFinder, matching: find.byType(Transform))
          .first;

      // Initial translation should be 0.0
      var transform = tester.widget<Transform>(translateFinder);
      expect(transform.transform.getTranslation().x, equals(0.0));

      // Tap Next button
      await tester.tap(buttonFinder);
      expect(pressed, isTrue);

      // Start animation ticker
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // Button should have bounced to the right (positive offset > 2.0)
      transform = tester.widget<Transform>(translateFinder);
      final offsetRight = transform.transform.getTranslation().x;
      expect(offsetRight, greaterThan(2.0));

      // Settle spring animation
      await tester.pumpAndSettle();

      // Button should be back at exact 0.0 resting position
      transform = tester.widget<Transform>(translateFinder);
      expect(transform.transform.getTranslation().x, closeTo(0.0, 0.05));
    });

    testWidgets(
      'Previous button bounces left and returns to initial position',
      (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: BouncingSkipButton.previous(
                  icon: FlutterRemix.skip_back_fill,
                  color: Colors.white,
                  onPressed: () => pressed = true,
                ),
              ),
            ),
          ),
        );

        final buttonFinder = find.byType(BouncingSkipButton);
        expect(buttonFinder, findsOneWidget);

        final translateFinder = find
            .descendant(of: buttonFinder, matching: find.byType(Transform))
            .first;

        // Tap Previous button
        await tester.tap(buttonFinder);
        expect(pressed, isTrue);

        // Start animation ticker
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));

        // Button should have bounced to the left (negative offset < -2.0)
        var transform = tester.widget<Transform>(translateFinder);
        final offsetLeft = transform.transform.getTranslation().x;
        expect(offsetLeft, lessThan(-2.0));

        // Settle spring animation
        await tester.pumpAndSettle();

        // Button should be back at resting position
        transform = tester.widget<Transform>(translateFinder);
        expect(transform.transform.getTranslation().x, closeTo(0.0, 0.05));
      },
    );

    testWidgets('Disabled button does not animate when pressed is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BouncingSkipButton.next(
                icon: FlutterRemix.skip_forward_fill,
                color: Colors.white,
                onPressed: null,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(BouncingSkipButton);
      final translateFinder = find
          .descendant(of: buttonFinder, matching: find.byType(Transform))
          .first;

      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final transform = tester.widget<Transform>(translateFinder);
      expect(transform.transform.getTranslation().x, equals(0.0));
    });

    testWidgets('Rapid taps compound velocity without glitching or throwing', (
      tester,
    ) async {
      int pressCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BouncingSkipButton.next(
                icon: FlutterRemix.skip_forward_fill,
                color: Colors.white,
                onPressed: () => pressCount++,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(BouncingSkipButton);

      // Tap 1
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      // Tap 2 in rapid succession
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      // Tap 3 in rapid succession
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(pressCount, equals(3));

      // Let animation settle completely
      await tester.pumpAndSettle();

      final translateFinder = find
          .descendant(of: buttonFinder, matching: find.byType(Transform))
          .first;
      final transform = tester.widget<Transform>(translateFinder);
      expect(transform.transform.getTranslation().x, closeTo(0.0, 0.05));
    });

    testWidgets('Button scales down by ~6% during bounce and returns to 1.0', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BouncingSkipButton.next(
                icon: FlutterRemix.skip_forward_fill,
                color: Colors.white,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(BouncingSkipButton);
      // Initial scale is 1.0
      final initialScaleTransform = tester
          .widgetList<Transform>(
            find.descendant(
              of: buttonFinder,
              matching: find.byType(Transform),
            ),
          )
          .elementAt(1);
      expect(
        initialScaleTransform.transform.storage[0],
        closeTo(1.0, 0.001),
      );

      // Tap Next button
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final transforms = tester
          .widgetList<Transform>(
            find.descendant(
              of: buttonFinder,
              matching: find.byType(Transform),
            ),
          )
          .toList();
      final scaleAtBounce = transforms[1].transform.storage[0];
      expect(scaleAtBounce, lessThan(0.99));
      expect(scaleAtBounce, greaterThanOrEqualTo(0.92));

      // Settle spring
      await tester.pumpAndSettle();
      final settledTransforms = tester
          .widgetList<Transform>(
            find.descendant(
              of: buttonFinder,
              matching: find.byType(Transform),
            ),
          )
          .toList();
      final settledScale = settledTransforms[1].transform.storage[0];
      expect(settledScale, closeTo(1.0, 0.005));
    });
  });
}
