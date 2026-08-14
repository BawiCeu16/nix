import 'package:flutter/material.dart';

/// Pre-cached typography styles for Nix to eliminate runtime font parsing overhead during build/scroll cycles.
abstract final class NixTypography {
  static TextStyle specialGothicLabelMedium(BuildContext context, Color color) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
      fontFamily: 'SpecialGothicExpandedOne',
      color: color,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle specialGothicHeadlineSmall(
    BuildContext context,
    Color color,
  ) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      fontFamily: 'SpecialGothicExpandedOne',
      fontWeight: FontWeight.w900,
      color: color,
    );
  }
}
