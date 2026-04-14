import 'package:flutter/material.dart';
import 'dart:math' as math;

enum CDCoverState { closed, halfOpen, fullDisc }

class NixCustomizableCDWidget extends StatelessWidget {
  final Widget? discImage; // Optional
  final Widget coverImage;
  final double rotationAngle;
  final CDCoverState state;
  final double size;
  final String? seedId;
  final bool splitWhenHalfOpen;
  final bool isSpinning;
  final bool resetRotation;
  final double rotateSpeed;

  const NixCustomizableCDWidget({
    super.key,
    this.discImage,
    required this.coverImage,
    this.rotationAngle = 0,
    this.state = CDCoverState.closed,
    this.size = 300,
    this.seedId,
    this.splitWhenHalfOpen = false,
    this.isSpinning = false,
    this.resetRotation = false,
    this.rotateSpeed = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // CD Disc Layer
          AnimatedSlide(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            offset: state == CDCoverState.halfOpen
                ? (splitWhenHalfOpen
                      ? const Offset(0.25, 0)
                      : const Offset(0.5, 0))
                : (state == CDCoverState.closed
                      ? Offset(-2 / size, -2 / size)
                      : Offset.zero),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              scale: state == CDCoverState.fullDisc ? 1.0 : 0.92,
              child: _SpinningDiscWrapper(
                isSpinning: isSpinning,
                resetRotation: resetRotation,
                rotateSpeed: rotateSpeed,
                baseRotationOffset: rotationAngle,
                child: RepaintBoundary(
                  child: _DiscWithTexture(
                    size: size,
                    image: discImage,
                    seedId: seedId,
                  ),
                ),
              ),
            ),
          ),

          // Cover Layer
          AnimatedSlide(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            offset: (splitWhenHalfOpen && state == CDCoverState.halfOpen)
                ? const Offset(-0.25, 0)
                : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              opacity: state == CDCoverState.fullDisc ? 0.0 : 1.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                scale: state == CDCoverState.fullDisc ? 0.8 : 1.0,
                child: RepaintBoundary(
                  child: IgnorePointer(
                    ignoring: state == CDCoverState.fullDisc,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Positioned.fill(child: coverImage),
                            const Positioned.fill(
                              child: _TextureOverlay(type: 'cover'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscWithTexture extends StatelessWidget {
  final double size;
  final Widget? image;
  final String? seedId;

  const _DiscWithTexture({required this.size, this.image, this.seedId});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _DonutClip(size * 0.16 / 1.8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              // Fallback to a silver color if no discImage is provided
              child: image ?? Container(color: const Color(0xFFD1D5DB)),
            ),
          ),
          _TextureOverlay(type: 'cd', size: size, seedId: seedId),
          // Dark textured inner ring to simulate real CD clamp area
          Container(
            width: size * 0.35,
            height: size * 0.35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withOpacity(0.4),
                width: size * 0.1,
              ),
            ),
          ),
          // Small clear lip directly around the inner transparent hole
          Container(
            width: size * 0.15 + 4,
            height: size * 0.15 + 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 3.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutClip extends CustomClipper<Path> {
  final double holeRadius;

  _DonutClip(this.holeRadius);

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: holeRadius,
        ),
      );
    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(_DonutClip oldClipper) =>
      holeRadius != oldClipper.holeRadius;
}

class _TextureOverlay extends StatelessWidget {
  final String type;
  final double? size;
  final String? seedId;

  const _TextureOverlay({required this.type, this.size, this.seedId});

  @override
  Widget build(BuildContext context) {
    Gradient? overlayGradient;

    if (type == 'cd') {
      final random = math.Random(seedId?.hashCode ?? 0);
      final rotation = seedId != null ? random.nextDouble() * math.pi * 2 : 0.0;
      final streakCount = seedId != null
          ? random.nextInt(2) + 2
          : 2; // either 2 or 3 streaks dynamically

      List<Color> colors = [];
      List<double> stops = [];

      for (int i = 0; i < streakCount * 2; i++) {
        double pos = i / (streakCount * 2);
        colors.add(
          i % 2 == 0
              ? Colors.black.withOpacity(0.05)
              : Colors.white.withOpacity(0.55),
        );
        stops.add(pos);
      }
      colors.add(Colors.black.withOpacity(0.05));
      stops.add(1.0);

      overlayGradient = SweepGradient(
        colors: colors,
        stops: stops,
        transform: GradientRotation(rotation),
      );
    } else {
      overlayGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.4), Colors.transparent],
      );
    }

    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: type == 'cd' ? BoxShape.circle : BoxShape.rectangle,
          gradient: overlayGradient,
        ),
      ),
    );
  }
}

class _SpinningDiscWrapper extends StatefulWidget {
  final Widget child;
  final bool isSpinning;
  final bool resetRotation;
  final double rotateSpeed;
  final double baseRotationOffset;

  const _SpinningDiscWrapper({
    required this.child,
    required this.isSpinning,
    this.resetRotation = false,
    this.rotateSpeed = 1.0,
    this.baseRotationOffset = 0,
  });

  @override
  State<_SpinningDiscWrapper> createState() => _SpinningDiscWrapperState();
}

class _SpinningDiscWrapperState extends State<_SpinningDiscWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final effectiveSpeed = widget.rotateSpeed <= 0 ? 0.1 : widget.rotateSpeed;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (80000 ~/ effectiveSpeed)),
    );
    if (widget.isSpinning && widget.rotateSpeed > 0) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _SpinningDiscWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rotateSpeed != oldWidget.rotateSpeed) {
      final effectiveSpeed = widget.rotateSpeed <= 0 ? 0.1 : widget.rotateSpeed;
      _controller.duration = Duration(milliseconds: (80000 ~/ effectiveSpeed));
      if (widget.isSpinning && widget.rotateSpeed > 0) {
        _controller.repeat();
      } else {
        if (widget.resetRotation) {
          _safeAnimateBack();
        } else {
          _safeStop();
        }
      }
    } else if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning && widget.rotateSpeed > 0) {
        _controller.repeat();
      } else {
        if (widget.resetRotation) {
          _safeAnimateBack();
        } else {
          _safeStop();
        }
      }
    } else if (!widget.isSpinning &&
        widget.resetRotation &&
        !oldWidget.resetRotation) {
      _safeAnimateBack();
    }
  }

  void _safeAnimateBack() {
    if (_controller.value > 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.animateBack(
            0.0,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutQuad,
          );
        }
      });
    }
  }

  void _safeStop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.stop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle:
              widget.baseRotationOffset * (math.pi / 180) +
              (_controller.value * 2 * math.pi),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
