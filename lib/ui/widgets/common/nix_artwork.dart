import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_m3shapes_extended/flutter_m3shapes_extended.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

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
    final settings = context.watch<SettingsProvider>();
    final shape = settings.artworkShape;

    Widget artwork = QueryArtworkWidget(
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
      artworkBorder: shape == ArtworkShape.rounded
          ? (borderRadius ?? BorderRadius.circular(8))
          : BorderRadius.zero,
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
    );

    if (shape == ArtworkShape.rounded) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: artwork,
      );
    }

    if (shape == ArtworkShape.circle) {
      return ClipOval(child: artwork);
    }

    // Advanced M3 Expressive Shapes
    switch (shape) {
      case ArtworkShape.arch:
        return M3EContainer.arch(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.oval:
        return M3EContainer.oval(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.pill:
        return M3EContainer.pill(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.diamond:
        return M3EContainer.diamond(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.gem:
        return M3EContainer.gem(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.verySunny:
        return M3EContainer.verySunny(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.sunny:
        return M3EContainer.sunny(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.cookie4:
        return M3EContainer.c4SidedCookie(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.cookie6:
        return M3EContainer.c6SidedCookie(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.cookie9:
        return M3EContainer.c9SidedCookie(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.cookie12:
        return M3EContainer.c12SidedCookie(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.pixelCircle:
        return M3EContainer.pixelCircle(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      case ArtworkShape.bun:
        return M3EContainer.bun(
          width: width,
          height: height,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: artwork,
        );
      default:
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: artwork,
        );
    }
  }
}
