import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nix/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NixApp(hasCompletedOnboarding: false));

    // Verify that the app builds successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
