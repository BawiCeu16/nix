import 'package:flutter/material.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/common/cd_widget.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';

/// Reusable card tile component for displaying album cover, title, and artist.
class AlbumCardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? firstTrackId;
  final VoidCallback? onTap;
  final double? size;

  const AlbumCardTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.firstTrackId,
    this.onTap,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final useCdArtworkStyle = context.select<SettingsProvider, bool>(
      (s) => s.useCdArtworkStyle,
    );
    final splitCdWhenHalfOpen = context.select<SettingsProvider, bool>(
      (s) => s.splitCdWhenHalfOpen,
    );

    final artworkWidget = useCdArtworkStyle
        ? NixCustomizableCDWidget(
            size: size ?? 160,
            state: CDCoverState.closed,
            splitWhenHalfOpen: splitCdWhenHalfOpen,
            seedId: title,
            coverImage: Stack(
              fit: StackFit.expand,
              children: [
                NixArtwork(
                  id: firstTrackId ?? 0,
                  type: ArtworkType.AUDIO,
                  fit: BoxFit.cover,
                ),
                Transform.scale(
                  scale: 1.15,
                  child: Image.asset(
                    'assets/cd_effects/cd_cover.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            discImage: NixArtwork(
              id: firstTrackId ?? 0,
              type: ArtworkType.AUDIO,
              fit: BoxFit.cover,
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: NixArtwork(
              id: firstTrackId ?? 0,
              type: ArtworkType.AUDIO,
              fit: BoxFit.cover,
              width: size,
              height: size,
            ),
          );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      // color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            size != null
                ? SizedBox(width: size, height: size, child: artworkWidget)
                : AspectRatio(aspectRatio: 1.0, child: artworkWidget),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
