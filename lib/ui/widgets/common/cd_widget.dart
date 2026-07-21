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
  final VoidCallback? onTap;

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // CD Disc Layer
            AnimatedSlide(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              offset: state == CDCoverState.halfOpen
                  ? (splitWhenHalfOpen
                        ? const Offset(0.28, 0)
                        : const Offset(0.55, 0))
                  : (state == CDCoverState.closed
                        ? Offset(-2 / size, -2 / size)
                        : Offset.zero),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                scale: state == CDCoverState.fullDisc ? 1.0 : 0.94,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: state == CDCoverState.closed ? 0.0 : 0.28,
                        ),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(6, 6),
                      ),
                    ],
                  ),
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
            ),

            // Cover Layer (Jewel Case)
            AnimatedSlide(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              offset: (splitWhenHalfOpen && state == CDCoverState.halfOpen)
                  ? const Offset(-0.28, 0)
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
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
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
              child: image ?? Container(color: const Color(0xFFD1D5DB)),
            ),
          ),
          // Rainbow & Specular Light Overlay
          _TextureOverlay(type: 'cd', size: size, seedId: seedId),

          // Outer Grooves Ring Line
          Container(
            width: size * 0.88,
            height: size * 0.88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
          ),

          // Dark textured inner ring to simulate real CD clamp area
          Container(
            width: size * 0.36,
            height: size * 0.36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.45),
                width: size * 0.08,
              ),
            ),
          ),
          // Transparent plastic clamp ring bevel
          Container(
            width: size * 0.22,
            height: size * 0.22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2.0,
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
                color: Colors.white.withValues(alpha: 0.7),
                width: 2.5,
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
    if (type == 'cd') {
      final random = math.Random(seedId?.hashCode ?? 0);
      final rotation = seedId != null ? random.nextDouble() * math.pi * 2 : 0.0;

      final overlayGradient = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.black.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.65),
          Colors.black.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.55),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(rotation),
      );

      return IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: overlayGradient,
          ),
        ),
      );
    } else {
      // Jewel Case Plastic Texture Overlay
      return IgnorePointer(
        child: Stack(
          children: [
            // Glass sheen gradient
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.12),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Left Hinge Plastic Ridge
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 14,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
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
