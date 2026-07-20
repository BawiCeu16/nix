import 'package:flutter/material.dart';

/// Holds all computed animation values and states for the NowPlaying sheet.
class PlayerAnimationData {
  final double progress;
  final double clampedProgress;
  final double inverseProgress;
  final double inverseClampedProgress;
  final double reverseProgress;
  final double reverseClampedProgress;
  final double queueProgress;
  final double queueClampedProgress;
  final double bounceProgress;
  final double bounceClampedProgress;
  final double opacity;
  final double fastOpacity;
  final double topRowOpacity;
  final double bottomOffset;
  final double panelHeight;
  final BorderRadius borderRadius;

  PlayerAnimationData({
    required this.progress,
    required this.clampedProgress,
    required this.inverseProgress,
    required this.inverseClampedProgress,
    required this.reverseProgress,
    required this.reverseClampedProgress,
    required this.queueProgress,
    required this.queueClampedProgress,
    required this.bounceProgress,
    required this.bounceClampedProgress,
    required this.opacity,
    required this.fastOpacity,
    required this.topRowOpacity,
    required this.bottomOffset,
    required this.panelHeight,
    required this.borderRadius,
  });
}
