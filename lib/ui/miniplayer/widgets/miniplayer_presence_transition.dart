import 'package:flutter/material.dart';
import 'package:nix/core/motion.dart';

/// Wraps the Miniplayer with a high-performance fade in / fade out animation
/// whenever playback starts or stops/clears.
///
/// Features:
/// - Smooth entrance with [NixCurves.expressiveDecelerated] (350ms).
/// - Graceful exit with [NixCurves.expressiveAccelerated] (250ms).
/// - Unmounts to [SizedBox.shrink] once completely faded out to eliminate GPU paint
///   and gesture hit testing overhead.
/// - Retains the active child during reverse fade out to avoid abrupt visual pops.
class MiniplayerPresenceTransition extends StatefulWidget {
  final bool hasTrack;
  final Widget child;

  const MiniplayerPresenceTransition({
    super.key,
    required this.hasTrack,
    required this.child,
  });

  @override
  State<MiniplayerPresenceTransition> createState() =>
      _MiniplayerPresenceTransitionState();
}

class _MiniplayerPresenceTransitionState
    extends State<MiniplayerPresenceTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  Widget? _lastActiveChild;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: NixDurations.medium,
      reverseDuration: NixDurations.short,
      value: widget.hasTrack ? 1.0 : 0.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: NixCurves.expressiveDecelerated,
      reverseCurve: NixCurves.expressiveAccelerated,
    );
    if (widget.hasTrack) {
      _lastActiveChild = widget.child;
    }
  }

  @override
  void didUpdateWidget(MiniplayerPresenceTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasTrack) {
      _lastActiveChild = widget.child;
    }
    if (widget.hasTrack != oldWidget.hasTrack) {
      if (widget.hasTrack) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasTrack) {
      _lastActiveChild = widget.child;
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, _) {
        final double opacity = _fadeAnimation.value;
        if (opacity <= 0.001 && !widget.hasTrack) {
          _lastActiveChild = null;
          return const SizedBox.shrink();
        }

        final activeChild = widget.hasTrack
            ? widget.child
            : (_lastActiveChild ?? widget.child);

        return IgnorePointer(
          ignoring: !widget.hasTrack || opacity < 0.99,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: activeChild,
          ),
        );
      },
    );
  }
}
