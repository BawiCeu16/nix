import 'package:flutter/material.dart';

/// A circular Material 3 Expressive button that animates its scale when pressed.
/// This button is 1:1 and maintains a circular shape regardless of state.
class ExpressiveHugeButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double size;

  const ExpressiveHugeButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.size = 100.0,
  });

  @override
  State<ExpressiveHugeButton> createState() => _ExpressiveHugeButtonState();
}

class _ExpressiveHugeButtonState extends State<ExpressiveHugeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;

    final targetScale = _isPressed ? 0.90 : 1.0;

    return AnimatedScale(
      scale: targetScale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuad,
      child: AnimatedContainer(
        height: widget.size,
        width: widget.size,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        decoration: BoxDecoration(
          color: enabled
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (isHighlighted) {
              if (enabled) {
                setState(() {
                  _isPressed = isHighlighted;
                });
              }
            },
            child: Center(
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: enabled
                      ? colorScheme.onPrimary
                      : colorScheme.onPrimaryContainer.withValues(alpha: 0.38),
                  fontWeight: FontWeight.w600,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
