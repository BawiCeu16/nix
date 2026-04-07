import 'package:flutter/material.dart';

/// A premium, bespoke slider widget for Nix music player.
/// Used for both Sleep Timer and Playback Speed to ensure visual consistency.
class NixSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String label;

  const NixSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2.5,
        thumbShape: _NixThumbShape(
          label: label,
          color: colorScheme.primary,
          textColor: colorScheme.onPrimary,
        ),
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.15),
        overlayColor: colorScheme.primary.withValues(alpha: 0.1),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

class _NixThumbShape extends SliderComponentShape {
  final String label;
  final Color color;
  final Color textColor;

  const _NixThumbShape({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(64, 32);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw a pill-shaped thumb
    // Adjusted width to fit the text better
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final thumbWidth = textPainter.width + 24;
    final thumbHeight = 22.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight),
      const Radius.circular(100),
    );
    canvas.drawRRect(rrect, paint);

    // Draw the text inside the thumb
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}
