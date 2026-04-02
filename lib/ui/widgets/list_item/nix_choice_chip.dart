import 'package:flutter/material.dart';

class NixChoiceChip<T> extends StatefulWidget {
  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final bool isFirst;
  final bool isLast;

  const NixChoiceChip({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<NixChoiceChip<T>> createState() => _NixChoiceChipState<T>();
}

class _NixChoiceChipState<T> extends State<NixChoiceChip<T>> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed != pressed && mounted) {
      setState(() => _isPressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.value == widget.groupValue;
    final colorScheme = Theme.of(context).colorScheme;

    final targetScale = _isPressed ? 0.96 : 1.0;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () => widget.onChanged(widget.value),
      child: AnimatedScale(
        scale: targetScale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuad,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                (isSelected || widget.isFirst) ? 100 : 5,
              ),
              bottomLeft: Radius.circular(
                (isSelected || widget.isFirst) ? 100 : 5,
              ),
              topRight: Radius.circular(
                (isSelected || widget.isLast) ? 100 : 5,
              ),
              bottomRight: Radius.circular(
                (isSelected || widget.isLast) ? 100 : 5,
              ),
            ),
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutQuad,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}
