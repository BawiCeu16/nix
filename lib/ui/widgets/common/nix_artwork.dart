import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/models/settings/artwork_quality.dart';
import 'package:nix/providers/artwork_provider.dart';

/// A high-performance, parallelized artwork widget for Nix.
///
/// Features:
/// - Isolated per-key [ValueListenable] subscription: zero global rebuild sweeps.
/// - Synchronous memory cache fast-path: instantaneous 0-frame rendering without
///   placeholder flashes or unnecessary animation overhead.
/// - Hardware texture downscaling via [cacheWidth] / [cacheHeight].
/// - [RepaintBoundary] layer isolation preventing paint invalidation cascades
///   up to parent scroll views during fast flings.
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

    // Read ArtworkProvider without subscribing to global ChangeNotifier notifications
    final artworkProv = context.read<ArtworkProvider>();
    final double? pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio;
    final int? targetCacheWidth =
        width != null &&
            width! > 0 &&
            width! < double.infinity &&
            pixelRatio != null
        ? (width! * pixelRatio).round()
        : null;
    final int? targetCacheHeight =
        height != null &&
            height! > 0 &&
            height! < double.infinity &&
            pixelRatio != null
        ? (height! * pixelRatio).round()
        : null;

    final filterQuality = _getFilterQuality(currentQuality);

    // Synchronous memory cache fast-path
    final syncBytes = artworkProv.getSync(id, type, currentQuality);

    Widget content;
    if (syncBytes != null) {
      // Immediate synchronous render: zero microtasks, zero placeholder flash, zero animation
      content = Image.memory(
        syncBytes,
        key: ValueKey('art_sync_${id}_${currentQuality.name}'),
        fit: fit,
        width: width,
        height: height,
        cacheWidth: targetCacheWidth,
        cacheHeight: targetCacheHeight,
        filterQuality: filterQuality,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallback(colorScheme),
      );
    } else {
      // Asynchronous background load: subscribe strictly to this specific key's notifier
      final notifier = artworkProv.getArtworkNotifier(id, type, currentQuality);

      content = ValueListenableBuilder<Uint8List?>(
        valueListenable: notifier,
        builder: (context, bytes, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: bytes != null
                ? Image.memory(
                    bytes,
                    key: ValueKey('art_async_${id}_${currentQuality.name}'),
                    fit: fit,
                    width: width,
                    height: height,
                    cacheWidth: targetCacheWidth,
                    cacheHeight: targetCacheHeight,
                    filterQuality: filterQuality,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFallback(colorScheme),
                  )
                : _buildFallback(colorScheme),
          );
        },
      );
    }

    Widget artworkWidget = RepaintBoundary(
      child: shape == ArtworkShape.circle
          ? ClipOval(child: content)
          : ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(12.0),
              child: content,
            ),
    );

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
