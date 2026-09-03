import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';
import 'nix_durations.dart';
import 'nix_springs.dart';

/// Custom physics-based scroll physics powered by Nix spring tokens.
class NixSpringScrollPhysics extends BouncingScrollPhysics {
  /// Creates scroll physics powered by [spring].
  const NixSpringScrollPhysics({
    super.parent,
    this.springMotion,
  });

  /// Optional custom spring motion for overscroll settling.
  final SpringMotion? springMotion;

  @override
  NixSpringScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return NixSpringScrollPhysics(
      parent: buildParent(ancestor),
      springMotion: springMotion,
    );
  }

  @override
  SpringDescription get spring {
    if (springMotion != null) {
      return springMotion!.description;
    }
    return NixSprings.queueSlide.description;
  }
}

/// Helper extensions for working with Flutter [AnimationController] and Motor [Motion].
extension NixAnimationControllerExtensions on AnimationController {
  /// Animates this controller using a Motor [Motion].
  ///
  /// Automatically dispatches spring physics or duration-based simulation based on motion type.
  TickerFuture animateWithMotion(
    Motion motion, {
    double target = 1.0,
    double initialVelocity = 0.0,
  }) {
    if (motion is CurvedMotion) {
      return animateTo(
        target,
        duration: motion.duration,
        curve: motion.curve,
      );
    } else if (motion is SpringMotion) {
      final Simulation simulation = motion.createSimulation(
        start: value,
        end: target,
        velocity: initialVelocity,
      );
      return animateWith(simulation);
    } else {
      final Simulation simulation = motion.createSimulation(
        start: value,
        end: target,
        velocity: initialVelocity,
      );
      return animateWith(simulation);
    }
  }

  /// Animates this controller using a [SpringMotion].
  TickerFuture animateWithSpring(
    SpringMotion spring, {
    double target = 1.0,
    double initialVelocity = 0.0,
  }) {
    final Simulation simulation = spring.createSimulation(
      start: value,
      end: target,
      velocity: initialVelocity,
    );
    return animateWith(simulation);
  }

  /// Animates this controller using a [CurvedMotion].
  TickerFuture animateWithCurvedMotion(
    CurvedMotion motion, {
    double target = 1.0,
  }) {
    return animateTo(
      target,
      duration: motion.duration,
      curve: motion.curve,
    );
  }
}

/// Extension methods for converting standard Flutter [Curve] to Motor [CurvedMotion].
extension NixCurveExtensions on Curve {
  /// Wraps this [Curve] into a Motor [CurvedMotion] with [duration].
  CurvedMotion toCurvedMotion([Duration duration = NixDurations.medium]) {
    return CurvedMotion(duration, this);
  }
}
