import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_remix/flutter_remix.dart';

/// A high-performance, high-fidelity artwork widget for Nix.
/// Enforces 'best of the best' quality by using tiered resolution queries,
/// lossless PNG format, and advanced filtering.
enum NixArtworkQuality {
  /// Standard quality (200px) - Perfect for list items and thumbnails (1.4x 48dp @ 3x).
  low,

  /// Medium quality (500px) - Perfect for cards and collection grids.
  medium,

  /// Full-high quality (1000px) - Best for full-screen covers and headers.
  high,
}

class NixArtwork extends StatelessWidget {
  /// The ID of the song/album to query artwork for.
  final int id;

  /// The type of artwork (AUDIO or ALBUM).
  final ArtworkType type;

  /// The shape/border of the artwork.
  final BorderRadius? borderRadius;

  /// The fit of the artwork.
  final BoxFit fit;

  /// The quality tier for the artwork query.
  /// Standard: low (200px), Medium: 500px, High: 1000px.
  final NixArtworkQuality quality;

  final double? width;
  final double? height;

  const NixArtwork({
    super.key,
    required this.id,
    this.type = ArtworkType.AUDIO,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.quality = NixArtworkQuality.low,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: QueryArtworkWidget(
        id: id,
        type: type,
        // High fidelity tiered configurations
        format: ArtworkFormat.PNG, // Lossless transparency and color
        size: quality == NixArtworkQuality.high
            ? 1000
            : (quality == NixArtworkQuality.medium ? 500 : 200),
        artworkQuality: FilterQuality.high, // Enforce high-quality resizing
        artworkFit: fit,
        artworkWidth: width ?? 50.0,
        artworkHeight: height ?? 50.0,
        keepOldArtwork: quality != NixArtworkQuality.low,
        artworkBorder: borderRadius ?? BorderRadius.zero,
        nullArtworkWidget: Container(
          width: width,
          height: height,
          color: colorScheme.secondaryContainer,
          child: Center(
            child: Icon(
              type == ArtworkType.AUDIO
                  ? FlutterRemix.music_2_line
                  : FlutterRemix.album_line,
              color: colorScheme.onSecondaryContainer.withValues(alpha: .5),
              size: (width ?? 48) * 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
