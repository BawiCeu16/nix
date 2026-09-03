import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:m3e_buttons/m3e_buttons.dart';

class NixSectionHeader extends StatelessWidget {
  final String title;
  final double topPadding;
  final VoidCallback? onShowAll;
  final String showAllLabel;

  const NixSectionHeader({
    super.key,
    required this.title,
    this.topPadding = 24,
    this.onShowAll,
    this.showAllLabel = 'See All',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(left: 8, top: topPadding, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onShowAll != null)
            M3EFilledButton.tonal(
              size: M3EButtonSize.custom(hPadding: 0, height: 48, width: 38),
              decoration: M3EButtonDecoration.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
              onPressed: onShowAll,
              child: const Icon(FlutterRemix.arrow_right_line),
            ),
        ],
      ),
    );
  }
}
