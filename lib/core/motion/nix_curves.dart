import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:motor/motor.dart';
import 'nix_durations.dart';

/// Standardized duration-based animation curves and Motor [CurvedMotion] presets for Nix.
///
/// Combines Material 3 Expressive curves, signature springy cubic curves, and motor [CurvedMotion] presets.
@immutable
abstract final class NixCurves {
  const NixCurves._();

  // --- Signature Nix Curves ---
  /// Signature bouncing curve for Miniplayer sheet snapping, lyrics expansion, and menu pops.
  static const Cubic bouncing = Cubic(0.175, 1.185, 0.80, 1.0);

  /// Springy curve for scale gestures, floating toolbar popups, and dynamic button bounces.
  static const Cubic springy = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Snappy curve for quick list updates, track reordering, and slider handle updates.
  static const Cubic snappy = Cubic(0.2, 0.9, 0.3, 1.0);

  // --- Material 3 Expressive Curves ---
  /// Expressive Emphasized easing - starts fast, decelerates smoothly with strong emphasis.
  static const Cubic expressiveEmphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Expressive Decelerated easing - fast entrance, soft landing.
  static const Cubic expressiveDecelerated = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Expressive Accelerated easing - gentle start, quick exit.
  static const Cubic expressiveAccelerated = Cubic(0.3, 0.0, 0.8, 0.15);

  // --- Standard Flutter Utilities ---
  /// Standard smooth ease-in-out cubic curve.
  static const Curve standard = Curves.easeInOutCubic;

  /// Standard ease-out decelerate curve.
  static const Curve standardDecelerate = Curves.easeOutCubic;

  /// Standard ease-in accelerate curve.
  static const Curve standardAccelerate = Curves.easeInCubic;

  /// Linear curve for constant speed animations like CD rotation.
  static const Curve linear = Curves.linear;
}

/// Pre-configured Motor [CurvedMotion] presets combining [NixDurations] and [NixCurves].
///
/// Ready for instant use with Motor's `MotionController`, `MotionBuilder`, or converted to standard Flutter [Curve] via `.toCurve`.
@immutable
abstract final class NixCurvedMotions {
  const NixCurvedMotions._();

  /// Quick 180ms motor curved motion for track swiping and immediate UI changes.
  static const CurvedMotion fast = CurvedMotion(
    NixDurations.fast,
    NixCurves.expressiveDecelerated,
  );

  /// Short 250ms motor curved motion for button scale feedback and chip toggles.
  static const CurvedMotion short = CurvedMotion(
    NixDurations.short,
    NixCurves.expressiveEmphasized,
  );

  /// Medium 350ms motor curved motion for Miniplayer expansion, modal dialogs, and drawer menus.
  static const CurvedMotion medium = CurvedMotion(
    NixDurations.medium,
    NixCurves.expressiveEmphasized,
  );

  /// Long 500ms motor curved motion for page transitions and lyrics view transitions.
  static const CurvedMotion long = CurvedMotion(
    NixDurations.long,
    NixCurves.expressiveEmphasized,
  );

  /// Bouncy 350ms motor curved motion using Nix signature bounce physics curve.
  static const CurvedMotion bouncy = CurvedMotion(
    NixDurations.medium,
    NixCurves.bouncing,
  );

  /// Snappy 250ms motor curved motion for fast snappy list item updates.
  static const CurvedMotion snappy = CurvedMotion(
    NixDurations.short,
    NixCurves.snappy,
  );
}
