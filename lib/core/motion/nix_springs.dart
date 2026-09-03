import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';
import 'nix_durations.dart';

/// Physics-based spring tokens and Motor [SpringMotion] configurations for Nix.
///
/// Combines Cupertino fluid physics, Material 3 Expressive spring tokens,
/// and custom component-tailored physics for the Nix player experience.
@immutable
abstract final class NixSprings {
  const NixSprings._();

  // --- Cupertino Physics Springs ---
  /// Bouncy spring animation with higher bounce for playful UI interactions.
  static const CupertinoMotion bouncy = CupertinoMotion.bouncy(
    duration: NixDurations.long,
  );

  /// Snappy spring animation with slight bounce for responsive controls.
  static const CupertinoMotion snappy = CupertinoMotion.snappy(
    duration: NixDurations.medium,
  );

  /// Smooth spring animation with zero bounce for fluid layout transitions.
  static const CupertinoMotion smooth = CupertinoMotion.smooth(
    duration: NixDurations.medium,
  );

  /// Low-response interactive spring ideal for gesture-driven drag and swipe tracking.
  static const CupertinoMotion interactive = CupertinoMotion.interactive(
    duration: NixDurations.fast,
  );

  // --- Material 3 Expressive Spatial Springs ---
  /// Standard spatial fast spring (Stiffness: 1400, Damping Ratio: 0.9).
  static const MaterialSpringMotion spatialFast =
      MaterialSpringMotion.standardSpatialFast();

  /// Standard spatial default spring (Stiffness: 700, Damping Ratio: 0.9).
  static const MaterialSpringMotion spatialDefault =
      MaterialSpringMotion.standardSpatialDefault();

  /// Standard spatial slow spring (Stiffness: 300, Damping Ratio: 0.9).
  static const MaterialSpringMotion spatialSlow =
      MaterialSpringMotion.standardSpatialSlow();

  /// Expressive spatial fast spring with lower damping for bouncy spatial motion (Stiffness: 800, Damping Ratio: 0.6).
  static const MaterialSpringMotion expressiveSpatialFast =
      MaterialSpringMotion.expressiveSpatialFast();

  /// Expressive spatial default spring (Stiffness: 380, Damping Ratio: 0.8).
  static const MaterialSpringMotion expressiveSpatialDefault =
      MaterialSpringMotion.expressiveSpatialDefault();

  /// Expressive spatial slow spring (Stiffness: 200, Damping Ratio: 0.8).
  static const MaterialSpringMotion expressiveSpatialSlow =
      MaterialSpringMotion.expressiveSpatialSlow();

  // --- Material 3 Expressive Effects Springs ---
  /// Standard effects fast spring for non-spatial properties like opacity (Stiffness: 3800, Damping: 1.0).
  static const MaterialSpringMotion effectsFast =
      MaterialSpringMotion.standardEffectsFast();

  /// Standard effects default spring (Stiffness: 1600, Damping: 1.0).
  static const MaterialSpringMotion effectsDefault =
      MaterialSpringMotion.standardEffectsDefault();

  /// Standard effects slow spring (Stiffness: 800, Damping: 1.0).
  static const MaterialSpringMotion effectsSlow =
      MaterialSpringMotion.standardEffectsSlow();

  // --- Custom Nix Component Physics Springs ---
  /// High-response physics spring for Miniplayer vertical sheet snapping and expansion.
  static final SpringMotion miniplayerSnap = SpringMotion(
    SpringDescription.withDampingRatio(
      ratio: 0.78,
      stiffness: 420.0,
      mass: 0.85,
    ),
    snapToEnd: true,
  );

  /// Crisp low-mass physics spring for NowPlaying artwork and track swiping.
  static final SpringMotion trackSwipe = SpringMotion(
    SpringDescription.withDampingRatio(
      ratio: 0.82,
      stiffness: 650.0,
      mass: 0.6,
    ),
    snapToEnd: true,
  );

  /// Highly responsive micro-spring for tactile button feedback and touch scaling.
  static final SpringMotion buttonPress = SpringMotion(
    SpringDescription.withDampingRatio(
      ratio: 0.70,
      stiffness: 900.0,
      mass: 0.4,
    ),
    snapToEnd: true,
  );

  /// Fluid physics spring for queue list item reorder and sliding.
  static final SpringMotion queueSlide = SpringMotion(
    SpringDescription.withDampingRatio(
      ratio: 0.85,
      stiffness: 400.0,
      mass: 1.0,
    ),
    snapToEnd: true,
  );

  /// Dynamic physics spring for album artwork expand/collapse morphing.
  static final SpringMotion artworkMorph = SpringMotion(
    SpringDescription.withDampingRatio(
      ratio: 0.75,
      stiffness: 480.0,
      mass: 0.9,
    ),
    snapToEnd: true,
  );

  // --- Factory Methods ---
  /// Creates a custom [SpringMotion] with specific mass, stiffness, and damping values.
  static SpringMotion custom({
    double mass = 1.0,
    required double stiffness,
    required double damping,
    bool snapToEnd = false,
  }) {
    return SpringMotion(
      SpringDescription(
        mass: mass,
        stiffness: stiffness,
        damping: damping,
      ),
      snapToEnd: snapToEnd,
    );
  }

  /// Creates a custom [SpringMotion] using damping ratio (underdamped < 1.0, critically damped = 1.0, overdamped > 1.0).
  static SpringMotion withDampingRatio({
    required double ratio,
    required double stiffness,
    double mass = 1.0,
    bool snapToEnd = false,
  }) {
    return SpringMotion(
      SpringDescription.withDampingRatio(
        ratio: ratio,
        stiffness: stiffness,
        mass: mass,
      ),
      snapToEnd: snapToEnd,
    );
  }

  /// Creates a custom [SpringMotion] configured by estimated duration and bounce ratio.
  static SpringMotion withDurationAndBounce({
    required Duration duration,
    double bounce = 0.0,
    bool snapToEnd = false,
  }) {
    return SpringMotion(
      SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: bounce,
      ),
      snapToEnd: snapToEnd,
    );
  }
}
