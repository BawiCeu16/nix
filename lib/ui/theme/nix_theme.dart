import 'package:flutter/material.dart';

/// Centralised Theme generator for Nix.
/// Uses Material 3 design system with dynamic or custom seed colors.
abstract final class NixTheme {
  /// Builds a dark theme from a primary seed color.
  static ThemeData buildDarkTheme(Color seedColor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      splashFactory: NoSplash.splashFactory,
      useMaterial3: true,
    );
  }

  /// Builds a light theme from a primary seed color.
  static ThemeData buildLightTheme(Color seedColor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      splashFactory: NoSplash.splashFactory,
      useMaterial3: true,
    );
  }
}
