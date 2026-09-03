import 'package:flutter/foundation.dart';

/// Centralized animation duration tokens for the Nix design system.
///
/// Designed to provide consistent motion timings across the entire application,
/// matching Material 3 Expressive and iOS fluid motion standards.
@immutable
abstract final class NixDurations {
  const NixDurations._();

  /// Instant transition (0ms).
  static const Duration instant = Duration.zero;

  /// Micro interaction duration (100ms) - for instant tactile touch feedback and micro-toggles.
  static const Duration micro = Duration(milliseconds: 100);

  /// Fast transition (180ms) - for quick track swiping, popovers, and immediate UI state changes.
  static const Duration fast = Duration(milliseconds: 180);

  /// Short transition (250ms) - for button scaling, chip selection, and badge updates.
  static const Duration short = Duration(milliseconds: 250);

  /// Medium transition (350ms) - standard duration for miniplayer expansion, dialog transitions, and list item updates.
  static const Duration medium = Duration(milliseconds: 350);

  /// Long transition (500ms) - for full-screen route transitions, lyrics expansion, and drawer slides.
  static const Duration long = Duration(milliseconds: 500);

  /// Expressive motion duration (600ms) - for fluid physics-driven spring settling and dynamic morphing.
  static const Duration expressive = Duration(milliseconds: 600);

  /// Slow transition (750ms) - for deliberate background crossfades and multi-phase sequence animations.
  static const Duration slow = Duration(milliseconds: 750);

  /// Hero transition (1000ms) - for elaborate layout transitions and onboarding scene changes.
  static const Duration hero = Duration(milliseconds: 1000);
}
