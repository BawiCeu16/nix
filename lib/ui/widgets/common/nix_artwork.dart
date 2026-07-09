import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/settings/artwork_quality.dart';
import 'package:nix/providers/artwork_provider.dart';

/// A high-performance, high-fidelity artwork widget for Nix.
/// Enforces 'best of the best' quality by using tiered resolution queries,
/// lossless PNG format, and advanced filtering.
class NixArtwork extends StatelessWidget {
  /// The ID of the track/album to query artwork for.
  final int id;

  /// The type of artwork (AUDIO or ALBUM).
  final ArtworkType type;

  /// The shape/border of the artwork.
  final BorderRadius? borderRadius;

  /// The fit of the artwork.
  final BoxFit fit;

  /// The quality tier for the artwork query.
  /// If null, use global setting from SettingsProvider.
  final NixArtworkQuality? quality;

  final double? width;
  final double? height;

  const NixArtwork({
    super.key,
    required this.id,
    this.type = ArtworkType.AUDIO,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.quality,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shape = context.select<SettingsProvider, ArtworkShape>(
      (s) => s.artworkShape,
    );
    final currentQuality =
        quality ??
        context.select<SettingsProvider, NixArtworkQuality>(
          (s) => s.artworkQuality,
        );

    Widget artwork = Selector<ArtworkProvider, Uint8List?>(
      selector: (_, artworkProv) =>
          artworkProv.getCachedArtwork(id, type, currentQuality),
      builder: (context, bytes, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: bytes != null
              ? Image.memory(
                  bytes,
                  key: ValueKey('art_$id'),
                  fit: fit,
                  width: width,
                  height: height,
                  filterQuality: _getFilterQuality(currentQuality),
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallback(colorScheme),
                )
              : _buildFallback(colorScheme),
        );
      },
    );

    Widget artworkWidget;

    if (shape == ArtworkShape.circle) {
      artworkWidget = ClipOval(child: artwork);
    } else {
      artworkWidget = ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12.0),
        child: artwork,
      );
    }

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: artworkWidget);
    }
    return artworkWidget;
  }

  FilterQuality _getFilterQuality(NixArtworkQuality quality) {
    switch (quality) {
      case NixArtworkQuality.high:
        return FilterQuality.high;
      case NixArtworkQuality.medium:
        return FilterQuality.medium;
      case NixArtworkQuality.low:
        return FilterQuality.low;
    }
  }

  Widget _buildFallback(ColorScheme colorScheme) {
    return Center(
      key: const ValueKey('fallback'),
      child: Icon(
        type == ArtworkType.ALBUM
            ? FlutterRemix.album_line
            : type == ArtworkType.ARTIST
            ? FlutterRemix.user_4_line
            : FlutterRemix.music_2_line,
        color: colorScheme.onSecondaryContainer.withValues(alpha: 0.5),
        size: (width != null && width! < double.infinity) ? width! * 0.4 : 24,
      ),
    );
  }
}
