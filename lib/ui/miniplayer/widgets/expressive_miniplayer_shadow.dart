import 'package:flutter/material.dart';
import 'package:nix/core/motion.dart';

/// Renders the Expressive linear gradient shadow above the bottom navigation bar
/// with buttery smooth fade in / fade out animations.
///
/// Features:
/// - Smooth opacity transitions on enable/disable, shadow opacity changes, and track presence.
/// - Scales with sheet expansion progress: fades out smoothly as the player expands.
/// - Zero GPU / layer overhead when disabled or resting offstage: returns [SizedBox.shrink]
///   when [effectiveAlpha] is <= 0.001.
/// - Passes touch events straight through via [IgnorePointer].
class ExpressiveMiniplayerShadow extends StatelessWidget {
  final Animation<double> sheetAnimation;
  final bool isVisible;
  final double shadowOpacity;

  const ExpressiveMiniplayerShadow({
    super.key,
    required this.sheetAnimation,
    required this.isVisible,
    required this.shadowOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final double targetOpacity = isVisible ? shadowOpacity : 0.0;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: targetOpacity),
      duration: NixDurations.short, // 250ms
      curve: NixCurves.expressiveDecelerated,
      builder: (context, animOpacity, _) {
        if (animOpacity <= 0.001) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: sheetAnimation,
          builder: (context, _) {
            final double sheetFade =
                (1.0 - sheetAnimation.value).clamp(0.0, 1.0);
            final double effectiveAlpha =
                (animOpacity * sheetFade).clamp(0.0, 1.0);

            if (effectiveAlpha <= 0.001) {
              return const SizedBox.shrink();
            }

            return IgnorePointer(
              child: Container(
                height: 120.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      surfaceColor.withValues(alpha: effectiveAlpha),
                      surfaceColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
