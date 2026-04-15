import 'package:flutter/material.dart';

/// A Material 3 Expressive button that animates its scale and border radius when pressed.
class ExpressiveToneButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ExpressiveToneButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
  });

  @override
  State<ExpressiveToneButton> createState() => _ExpressiveToneButtonState();
}

class _ExpressiveToneButtonState extends State<ExpressiveToneButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;

    final targetRadius = _isPressed ? 15.0 : 100.0;
    final targetScale = _isPressed ? 0.95 : 1.0;

    return AnimatedScale(
      scale: targetScale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuad,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        decoration: BoxDecoration(
          color: enabled
              ? colorScheme.primaryContainer
              : colorScheme.onSurface.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(targetRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            enableFeedback: false,
            onHighlightChanged: (isHighlighted) {
              if (enabled) {
                setState(() {
                  _isPressed = isHighlighted;
                });
              }
            },
            child: Padding(
              padding: widget.padding,
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: enabled
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface.withValues(alpha: 0.38),
                  fontWeight: FontWeight.w600,
                ),
                child: Center(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
