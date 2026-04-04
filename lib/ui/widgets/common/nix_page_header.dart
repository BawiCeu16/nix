import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NixPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? songId;
  final IconData fallbackIcon;
  final Widget? actionRow;

  const NixPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.songId,
    this.fallbackIcon = FlutterRemix.play_list_fill,
    this.actionRow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 300,
              height: 300,
              color: colorScheme.secondaryContainer,
              child: songId != null
                  ? QueryArtworkWidget(
                      id: songId!,
                      type: ArtworkType.AUDIO,
                      keepOldArtwork: true,
                      artworkFit: BoxFit.cover,
                      artworkBorder: BorderRadius.circular(8),
                      artworkQuality: FilterQuality.high,
                      artworkWidth: 800,
                      artworkHeight: 800,
                      nullArtworkWidget: Icon(
                        fallbackIcon,
                        size: 80,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    )
                  : Icon(
                      fallbackIcon,
                      size: 80,
                      color: colorScheme.onSecondaryContainer,
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionRow != null) ...[const SizedBox(height: 24), actionRow!],
        ],
      ),
    );
  }
}
