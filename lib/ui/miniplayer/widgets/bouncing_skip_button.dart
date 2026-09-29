import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nix/core/motion.dart';

/// Direction for the bounce animation.
enum BounceDirection {
  /// Bounces to the left (negative x translation). Used for Skip Previous.
  left(-1.0),

  /// Bounces to the right (positive x translation). Used for Skip Next.
  right(1.0);

  const BounceDirection(this.sign);

  /// Normalized multiplier for translation along the X axis.
  final double sign;
}

/// A highly-optimized bouncing skip button for player controls.
///
/// When pressed:
/// - Next track button bounces to the right and springs back with motor's [CupertinoMotion.bouncy].
/// - Previous track button bounces to the left and springs back with motor's [CupertinoMotion.bouncy].
///
/// Performance optimizations:
/// - Isolated render layer with [RepaintBoundary].
/// - Zero-rebuild transform animation: uses [AnimatedBuilder] with pre-built [child],
///   ensuring only the translation transform is updated at 60/120 FPS.
/// - Fluid physics re-targeting: rapid repeated taps smoothly compound and redirect velocity
///   without snapping or animation restarts.
class BouncingSkipButton extends StatefulWidget {
  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Icon to display (typically [FlutterRemix.skip_back_fill] or [FlutterRemix.skip_forward_fill]).
  final IconData icon;

  /// Icon color.
  final Color color;

  /// Size of the icon. Defaults to 36.0.
  final double iconSize;

  /// The bounce direction (left for previous, right for next).
  final BounceDirection direction;

  /// Optional tooltip for accessibility.
  final String? tooltip;

  const BouncingSkipButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.color,
    this.iconSize = 36.0,
    required this.direction,
    this.tooltip,
  });

  /// Factory constructor for Skip Previous button (bounces left).
  const BouncingSkipButton.previous({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.color,
    this.iconSize = 36.0,
    this.tooltip = 'Previous track',
  }) : direction = BounceDirection.left;

  /// Factory constructor for Skip Next button (bounces right).
  const BouncingSkipButton.next({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.color,
    this.iconSize = 36.0,
    this.tooltip = 'Next track',
  }) : direction = BounceDirection.right;

  @override
  State<BouncingSkipButton> createState() => _BouncingSkipButtonState();
}

class _BouncingSkipButtonState extends State<BouncingSkipButton>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _controller;

  /// Signature bouncy spring animation curve from the motor package.
  /// Tuned for responsive tactile feedback with playful spring overshoot.
  static const _bouncySpring = CupertinoMotion.bouncy(
    duration: Duration(milliseconds: 320),
    extraBounce: 0.08,
  );

  /// Calibrated impulse velocity generating a refined ~4.8px peak displacement.
  static const double _impulseVelocity = 175.0;

  /// Expected peak displacement used to normalize scale compression.
  static const double _expectedPeakDisplacement = 4.8;

  /// Maximum scale reduction during the bounce (6% smaller -> scale 0.94).
  static const double _scaleReduction = 0.08;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: _bouncySpring,
      vsync: this,
      initialValue: 0.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    if (widget.onPressed == null) return;

    // Subtle tactile haptic feedback on tap
    HapticFeedback.lightImpact();

    // Trigger bouncy horizontal spring animation.
    // If user is rapidly tapping, seamlessly redirect physics from current position & velocity.
    final targetVelocity = widget.direction.sign * _impulseVelocity;
    _controller.animateTo(0.0, withVelocity: targetVelocity);

    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates the transform rendering to its own composited layer
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Normalize displacement to compute subtle 6% scale-down on press bounce
          final progress = (_controller.value.abs() / _expectedPeakDisplacement)
              .clamp(0.0, 1.2);
          final scale = 1.0 - (_scaleReduction * progress);

          return Transform.translate(
            offset: Offset(_controller.value, 0.0),
            transformHitTests: false,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        // The IconButton tree is passed as child to AnimatedBuilder so it is NOT rebuilt on animation ticks
        child: IconButton(
          iconSize: widget.iconSize,
          tooltip: widget.tooltip,
          icon: Icon(widget.icon, color: widget.color),
          onPressed: widget.onPressed != null ? _handlePress : null,
        ),
      ),
    );
  }
}
