import 'package:flutter/material.dart';

/// A reusable icon button that matches the Nix app's expressive design language.
/// It features scale-down animation on press and a circular shape.
class NixIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  const NixIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 48.0,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });

  @override
  State<NixIconButton> createState() => _NixIconButtonState();
}

class _NixIconButtonState extends State<NixIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;

    final targetScale = _isPressed ? 0.9 : 1.0;

    return Tooltip(
      message: widget.tooltip ?? '',
      child: AnimatedScale(
        scale: targetScale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuad,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color:
                widget.backgroundColor ??
                (enabled
                    ? colorScheme.primaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.12)),
            shape: BoxShape.circle,
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    color:
                        widget.iconColor ??
                        (enabled
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface.withValues(alpha: 0.38)),
                    size: widget.size * 0.5,
                  ),
                  child: widget.icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
