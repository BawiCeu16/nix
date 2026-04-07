import 'package:flutter/material.dart';

/// Centralised Theme generator for Nix.
/// Uses Material 3 design system with dynamic or custom seed colors.
abstract final class NixTheme {
  /// Builds a dark theme from a primary seed color.
  static ThemeData buildDarkTheme(Color seedColor, {bool amoled = false}) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      splashFactory: NoSplash.splashFactory,
      useMaterial3: true,
    );

    if (amoled) {
      return baseTheme.copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: baseTheme.colorScheme.copyWith(
          surface: Colors.black,
          surfaceContainer: Colors.black,
          surfaceContainerHigh: const Color(0xFF111111),
          surfaceContainerHighest: const Color(0xFF1A1A1A),
          surfaceContainerLow: Colors.black,
          surfaceContainerLowest: Colors.black,
        ),
      );
    }

    return baseTheme;
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
