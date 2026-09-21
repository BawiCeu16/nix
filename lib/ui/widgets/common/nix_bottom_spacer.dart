import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/core/constants.dart';
import 'package:nix/core/motion/motion.dart';

/// A reusable spacer that automatically adjusts its height based on the
/// MiniPlayer visibility and system safe areas.
///
/// Smoothly animates height adjustments when the MiniPlayer is shown or dismissed,
/// preventing abrupt visual jumps in lists while adhering to Nix design motion curves.
class NixBottomSpacer extends StatelessWidget {
  /// Whether to use this spacer as a sliver.
  final bool isSliver;

  /// Additional padding to add on top of the calculated height.
  final double extraPadding;

  /// General duration of the spacer height transition animation.
  /// If [appearDuration] or [dismissDuration] are specified, they take precedence.
  final Duration? duration;

  /// Duration when the MiniPlayer appears and the spacer expands.
  /// Defaults to [NixDurations.medium] (350ms).
  final Duration? appearDuration;

  /// Duration when the MiniPlayer is dismissed and the spacer collapses.
  /// Defaults to [NixDurations.medium] (350ms).
  final Duration? dismissDuration;

  /// General animation curve for the height transition.
  /// If [appearCurve] or [dismissCurve] are specified, they take precedence.
  final Curve? curve;

  /// Animation curve when the MiniPlayer appears and the spacer expands.
  /// Defaults to [NixCurves.expressiveDecelerated] for a fast entrance and soft landing.
  final Curve? appearCurve;

  /// Animation curve when the MiniPlayer is dismissed and the spacer collapses.
  /// Defaults to [NixCurves.expressiveEmphasized] for a smooth, emphasized exit.
  final Curve? dismissCurve;

  const NixBottomSpacer({
    super.key,
    this.isSliver = false,
    this.extraPadding = 0.0,
    this.duration,
    this.appearDuration,
    this.dismissDuration,
    this.curve,
    this.appearCurve,
    this.dismissCurve,
  });

  /// Factory for using the spacer in a [CustomScrollView].
  const NixBottomSpacer.sliver({
    super.key,
    this.extraPadding = 0.0,
    this.duration,
    this.appearDuration,
    this.dismissDuration,
    this.curve,
    this.appearCurve,
    this.dismissCurve,
  }) : isSliver = true;

  @override
  Widget build(BuildContext context) {
    // OPTIMIZATION: Only listen to `showMiniPlayer` boolean changes rather than
    // rebuilding on every playback tick, seek, or queue change in CurrentMusicProvider.
    final showMiniPlayer = context.select<CurrentMusicProvider, bool>(
      (provider) => provider.showMiniPlayer,
    );

    // OPTIMIZATION: Subscribe specifically to bottom viewInsets to avoid rebuilding
    // when unrelated MediaQuery metrics change.
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    // Total height calculation:
    // NavigationScreen already restricts height by (NavBar + Safe Area).
    // We only need to clear the MiniPlayer (82px) if visible, or a 10px cushion.
    // 25px for extra above the MiniPlayer + 10px for cushion (or none showing MiniPlayer padding).
    final double targetHeight =
        (showMiniPlayer ? (NixConstants.kMiniPlayerHeight + 25.0) : 10.0) +
        viewInsets +
        NixConstants.kBottomPadding +
        extraPadding;

    // Select Nix-styled motion curve and duration tailored for appearing vs dismissing:
    // - Appearing: expressiveDecelerated gives a quick responsive entrance with a soft landing.
    // - Dismissing: expressiveEmphasized smoothly and deliberately settles the space closed.
    final effectiveDuration = showMiniPlayer
        ? (appearDuration ?? duration ?? NixDurations.medium)
        : (dismissDuration ?? duration ?? NixDurations.medium);

    final effectiveCurve = showMiniPlayer
        ? (appearCurve ?? curve ?? NixCurves.expressiveDecelerated)
        : (dismissCurve ?? curve ?? NixCurves.expressiveEmphasized);

    if (isSliver) {
      return SliverToBoxAdapter(
        child: _AnimatedSpacerBox(
          height: targetHeight,
          duration: effectiveDuration,
          curve: effectiveCurve,
        ),
      );
    }

    return _AnimatedSpacerBox(
      height: targetHeight,
      duration: effectiveDuration,
      curve: effectiveCurve,
    );
  }

  /// Calculates the required bottom height based on current context.
  static double calculateHeight(
    BuildContext context, {
    double extraPadding = 0.0,
  }) {
    final showMiniPlayer = context.read<CurrentMusicProvider>().showMiniPlayer;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return (showMiniPlayer ? (NixConstants.kMiniPlayerHeight + 25.0) : 10.0) +
        viewInsets +
        NixConstants.kBottomPadding +
        extraPadding;
  }
}

/// A lightweight implicitly animated widget that only tweens height into a [SizedBox].
///
/// Avoids the overhead of [AnimatedContainer] (which instantiates and interpolates
/// 10+ unrelated properties like decoration, padding, margin, transform, etc.).
class _AnimatedSpacerBox extends ImplicitlyAnimatedWidget {
  final double height;

  const _AnimatedSpacerBox({
    required this.height,
    required super.duration,
    required super.curve,
  });

  @override
  _AnimatedSpacerBoxState createState() => _AnimatedSpacerBoxState();
}

class _AnimatedSpacerBoxState
    extends AnimatedWidgetBaseState<_AnimatedSpacerBox> {
  Tween<double>? _heightTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _heightTween =
        visitor(
              _heightTween,
              widget.height,
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final double currentHeight =
        _heightTween?.evaluate(animation) ?? widget.height;

    return SizedBox(height: currentHeight);
  }
}
