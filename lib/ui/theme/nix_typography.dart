import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pre-cached typography styles for Nix to eliminate runtime font parsing overhead during build/scroll cycles.
abstract final class NixTypography {
  static final TextStyle _specialGothicBase = GoogleFonts.getFont(
    'Special Gothic Expanded One',
  );

  static TextStyle specialGothicLabelMedium(BuildContext context, Color color) {
    return _specialGothicBase.merge(
      Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static TextStyle specialGothicHeadlineSmall(
    BuildContext context,
    Color color,
  ) {
    return _specialGothicBase.merge(
      Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        color: color,
      ),
    );
  }
}
