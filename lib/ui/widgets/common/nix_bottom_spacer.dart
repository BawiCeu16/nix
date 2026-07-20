import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/core/constants.dart';

/// A reusable spacer that automatically adjusts its height based on the
/// MiniPlayer visibility and system safe areas.
///
/// Use this at the end of lists (ListView, CustomScrollView, etc.) to ensure
/// content is not covered when music is playing.
class NixBottomSpacer extends StatelessWidget {
  /// Whether to use this spacer as a sliver.
  final bool isSliver;

  /// Additional padding to add on top of the calculated height.
  final double extraPadding;

  const NixBottomSpacer({
    super.key,
    this.isSliver = false,
    this.extraPadding = 0.0,
  });

  /// Factory for using the spacer in a [CustomScrollView].
  const NixBottomSpacer.sliver({super.key, this.extraPadding = 0.0})
    : isSliver = true;

  @override
  Widget build(BuildContext context) {
    final showMiniPlayer = context.watch<CurrentMusicProvider>().showMiniPlayer;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    // Total height calculation:
    // NavigationScreen already restricts height by (NavBar + Safe Area).
    // We only need to clear the MiniPlayer (82px) if visible, or a 10px cushion.
    // 25px for extra above the MiniPlayer + 10px for cushion(or None showing Miniplayer padding)
    final double totalHeight =
        (showMiniPlayer ? (NixConstants.kMiniPlayerHeight + 25.0) : 10.0) +
        viewInsets +
        NixConstants.kBottomPadding +
        extraPadding;

    if (isSliver) {
      return SliverToBoxAdapter(child: SizedBox(height: totalHeight));
    }

    return SizedBox(height: totalHeight);
  }

  /// Calculates the required bottom height based on current context.
  static double calculateHeight(
    BuildContext context, {
    double extraPadding = 0.0,
  }) {
    final showMiniPlayer = context.read<CurrentMusicProvider>().showMiniPlayer;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return (showMiniPlayer ? (NixConstants.kMiniPlayerHeight + 25.0) : 10.0) +
        viewInsets +
        NixConstants.kBottomPadding +
        extraPadding;
  }
}
