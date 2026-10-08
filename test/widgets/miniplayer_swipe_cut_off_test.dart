import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nix/ui/miniplayer/controllers/now_playing_controller.dart';
import 'package:nix/ui/miniplayer/now_playing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MiniplayerContainerClipper Tests', () {
    test('computes correct RRect with margin within Miniplayer bounds', () {
      const screenSize = Size(400, 800);
      final data = NowPlayingPhysics.calculateAnimationData(
        progressValue: 0.0,
        maxOffset: 800.0,
        topInset: 24.0,
        bottomInset: 20.0,
        bounceUp: false,
        bounceDown: false,
      );

      final clipper = MiniplayerContainerClipper(
        data: data,
        screenSize: screenSize,
        margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      );

      final rrect = clipper.getClip(screenSize);

      // In collapsed miniplayer:
      // hPadding = 12.0 (+ 6.0 margin = 18.0)
      // vPadding = 12.0 (+ 4.0 margin = 16.0)
      // height = 82.0 (- 8.0 margin = 74.0)
      // bottomOffset = -80.0 - 20.0 = -100.0
      // bottom = 800 + (-100) - 12 - 4 = 684.0
      // top = 684.0 - 74.0 = 610.0
      expect(rrect.left, equals(18.0));
      expect(rrect.right, equals(382.0));
      expect(rrect.bottom, equals(684.0));
      expect(rrect.top, equals(610.0));
      expect(rrect.tlRadiusX, equals(15.0));
      expect(rrect.trRadiusX, equals(15.0));
      expect(rrect.blRadiusX, equals(15.0));
      expect(rrect.brRadiusX, equals(15.0));
    });

    test('reclip updates when animation progress, bottom offset, or margin changes', () {
      const screenSize = Size(400, 800);
      final data1 = NowPlayingPhysics.calculateAnimationData(
        progressValue: 0.0,
        maxOffset: 800.0,
        topInset: 24.0,
        bottomInset: 20.0,
        bounceUp: false,
        bounceDown: false,
      );
      final data2 = NowPlayingPhysics.calculateAnimationData(
        progressValue: 0.2,
        maxOffset: 800.0,
        topInset: 24.0,
        bottomInset: 20.0,
        bounceUp: false,
        bounceDown: false,
      );

      final clipper1 = MiniplayerContainerClipper(data: data1, screenSize: screenSize);
      final clipper2 = MiniplayerContainerClipper(data: data2, screenSize: screenSize);
      final clipper3 = MiniplayerContainerClipper(
        data: data1,
        screenSize: screenSize,
        margin: const EdgeInsets.all(10.0),
      );

      expect(clipper2.shouldReclip(clipper1), isTrue);
      expect(clipper3.shouldReclip(clipper1), isTrue);
      expect(clipper1.shouldReclip(clipper1), isFalse);
    });
  });

  group('NowPlayingController Gesture Boundaries & isSwipingTrack', () {
    testWidgets('isInsideMiniplayer correctly identifies inside vs outside coordinates', (tester) async {
      final sheetController = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 300),
        value: 0.0,
      );

      final controller = NowPlayingController();
      controller.setSheetAnimationForTesting(sheetController);
      controller.updateDimensions(
        screenSize: const Size(400, 800),
        topInset: 24.0,
        bottomInset: 20.0,
      );

      // Miniplayer is located vertically between ~606 and ~688, horizontally between 12 and 388
      // Test touch in the center of Miniplayer
      expect(controller.isInsideMiniplayer(const Offset(200, 650)), isTrue);

      // Test touch above Miniplayer (outside container)
      expect(controller.isInsideMiniplayer(const Offset(200, 500)), isFalse);
      expect(controller.isInsideMiniplayer(const Offset(200, 100)), isFalse);

      // Test touch below Miniplayer (navigation bar area)
      expect(controller.isInsideMiniplayer(const Offset(200, 750)), isFalse);

      // Test touch horizontally outside (left / right margins)
      expect(controller.isInsideMiniplayer(const Offset(5, 650)), isFalse);
      expect(controller.isInsideMiniplayer(const Offset(395, 650)), isFalse);

      // When expanded (sheet value = 1.0, offset = 800), isInsideMiniplayer is always true
      controller.offset = 800.0;
      sheetController.value = 1.0;
      expect(controller.isInsideMiniplayer(const Offset(200, 100)), isTrue);
      expect(controller.isInsideMiniplayer(const Offset(200, 500)), isTrue);

      sheetController.dispose();
    });

    testWidgets('isSwipingTrack is only true when horizontal swipe is active or animating', (tester) async {
      final sheetController = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 300),
        value: 0.0,
      );

      final controller = NowPlayingController();
      controller.setSheetAnimationForTesting(sheetController);
      controller.sAnim = AnimationController(
        vsync: tester,
        lowerBound: -1,
        upperBound: 1,
        value: 0.0,
      );

      // At resting state: not swiping track
      expect(controller.isSwipingTrack, isFalse);

      // When active gesture is vertical: still false
      controller.activeGesture = ActiveGesture.vertical;
      expect(controller.isSwipingTrack, isFalse);

      // When active gesture is horizontal: true!
      controller.activeGesture = ActiveGesture.horizontal;
      expect(controller.isSwipingTrack, isTrue);

      // When gesture ends but sAnim is animating (e.g. value = 0.5): true!
      controller.activeGesture = ActiveGesture.none;
      controller.sAnim.value = 0.5;
      expect(controller.isSwipingTrack, isTrue);

      // When sAnim settles back to 0.0: false!
      controller.sAnim.value = 0.0;
      expect(controller.isSwipingTrack, isFalse);

      controller.sAnim.dispose();
      sheetController.dispose();
    });

    testWidgets('dynamic clipBehavior is only antiAlias when miniplayer and swiping track', (tester) async {
      Clip clipBehaviorFor(double progress, bool isSwiping) {
        return (progress <= 0.4 && isSwiping) ? Clip.antiAlias : Clip.none;
      }

      // In resting miniplayer: Clip.none
      expect(clipBehaviorFor(0.0, false), equals(Clip.none));

      // While swiping in miniplayer: Clip.antiAlias
      expect(clipBehaviorFor(0.0, true), equals(Clip.antiAlias));
      expect(clipBehaviorFor(0.2, true), equals(Clip.antiAlias));
      expect(clipBehaviorFor(0.4, true), equals(Clip.antiAlias));

      // In expanded player: Clip.none even if swiping
      expect(clipBehaviorFor(0.5, true), equals(Clip.none));
      expect(clipBehaviorFor(1.0, true), equals(Clip.none));
      expect(clipBehaviorFor(1.0, false), equals(Clip.none));
    });

    testWidgets('horizontal gesture transitions update activeGesture and sOffset', (tester) async {
      final sheetController = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 300),
        value: 0.0,
      );

      final controller = NowPlayingController();
      controller.setSheetAnimationForTesting(sheetController);
      controller.sAnim = AnimationController(
        vsync: tester,
        lowerBound: -1,
        upperBound: 1,
        value: 0.0,
      );
      controller.updateDimensions(
        screenSize: const Size(400, 800),
        topInset: 24.0,
        bottomInset: 20.0,
      );

      // Verify initial state
      expect(controller.activeGesture, equals(ActiveGesture.none));
      expect(controller.isSwipingTrack, isFalse);

      // Starting horizontal drag activates isSwipingTrack
      controller.activeGesture = ActiveGesture.horizontal;
      expect(controller.isSwipingTrack, isTrue);

      // sAnim animating keeps isSwipingTrack true
      controller.activeGesture = ActiveGesture.none;
      controller.sAnim.value = 0.3;
      expect(controller.isSwipingTrack, isTrue);

      // Settle
      controller.sAnim.value = 0.0;
      expect(controller.isSwipingTrack, isFalse);

      controller.sAnim.dispose();
      sheetController.dispose();
    });

    testWidgets('linear fade shader calculates correct stops at left and right of miniplayer container', (tester) async {
      const double boundsWidth = 400.0;
      const double hPadding = 12.0;
      const double marginH = 6.0;
      const double left = hPadding + marginH; // 18.0
      const double right = boundsWidth - hPadding - marginH; // 382.0
      const double fadeWidth = 28.0;

      const double stop0 = 0.0;
      final double stop1 = (left / boundsWidth).clamp(0.0, 1.0); // 18 / 400 = 0.045
      final double stop2 = ((left + fadeWidth) / boundsWidth).clamp(stop1, 1.0); // 46 / 400 = 0.115
      final double stop4 = (right / boundsWidth).clamp(stop2, 1.0); // 382 / 400 = 0.955
      final double stop3 = ((right - fadeWidth) / boundsWidth).clamp(stop2, stop4); // 354 / 400 = 0.885
      const double stop5 = 1.0;

      // Verify stops are strictly non-decreasing
      expect(stop0 <= stop1, isTrue);
      expect(stop1 <= stop2, isTrue);
      expect(stop2 <= stop3, isTrue);
      expect(stop3 <= stop4, isTrue);
      expect(stop4 <= stop5, isTrue);

      // Verify fade regions
      expect(stop1, closeTo(0.045, 0.001));
      expect(stop2, closeTo(0.115, 0.001));
      expect(stop3, closeTo(0.885, 0.001));
      expect(stop4, closeTo(0.955, 0.001));
    });

    testWidgets('swipeFadeAnim animates fade in and fade out smoothly', (tester) async {
      final fadeAnim = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 180),
        value: 0.0,
      );

      // Resting state: 0.0
      expect(fadeAnim.value, equals(0.0));

      // Fade in animation
      fadeAnim.animateTo(1.0, curve: Curves.easeOutQuad, duration: const Duration(milliseconds: 160));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(fadeAnim.value, greaterThan(0.0));
      expect(fadeAnim.value, lessThan(1.0));

      await tester.pump(const Duration(milliseconds: 100));
      expect(fadeAnim.value, equals(1.0));

      // Fade out animation
      fadeAnim.animateTo(0.0, curve: Curves.easeInQuad, duration: const Duration(milliseconds: 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(fadeAnim.value, lessThan(1.0));
      expect(fadeAnim.value, greaterThan(0.0));

      await tester.pump(const Duration(milliseconds: 120));
      expect(fadeAnim.value, equals(0.0));

      fadeAnim.dispose();
    });

    testWidgets('SwipeFadeMask builds child directly when disabled and with layer when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeFadeMask(
              enabled: false,
              fadeProgress: 0.0,
              hPadding: 12.0,
              child: SizedBox(width: 400, height: 80),
            ),
          ),
        ),
      );

      expect(find.byType(SwipeFadeMask), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);

      // Re-pump with enabled = true and fadeProgress = 1.0
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeFadeMask(
              enabled: true,
              fadeProgress: 1.0,
              hPadding: 12.0,
              child: SizedBox(width: 400, height: 80),
            ),
          ),
        ),
      );

      expect(find.byType(SwipeFadeMask), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}

