import 'package:flutter/material.dart';

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
      padding: EdgeInsets.only(left: 8, top: topPadding, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                // letterSpacing: 1.2,
              ),
            ),
          ),
          if (onShowAll != null)
            TextButton(
              onPressed: onShowAll,
              child: Text(
                showAllLabel,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
