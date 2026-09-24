import 'package:flutter/material.dart';
import 'package:nix/core/app_initializer.dart';
import 'package:nix/providers/app_providers.dart';
import 'package:nix/ui/nix_app.dart';

export 'package:nix/ui/nix_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initResult = await AppInitializer.initialize();

  runApp(
    AppProviders(
      audioHandler: initResult.audioHandler,
      child: NixApp(hasCompletedOnboarding: initResult.hasCompletedOnboarding),
    ),
  );
}
