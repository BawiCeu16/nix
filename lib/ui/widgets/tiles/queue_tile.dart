import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nix/ui/widgets/tiles/m3e_track_tile.dart';

class QueueTile extends StatelessWidget {
  const QueueTile({
    super.key,
    this.title = "Queue Track",
    this.subtitle = "Queue Artist",
    this.trackId,
    this.itemIndex = 0,
    this.isPlaying = false,
    this.onTap,
    this.onRemove,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final int? trackId;
  final int itemIndex;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: M3EListItem(
          key: ValueKey('queue_${itemIndex}_$title'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 8.0,
          ),
          minHeight: 64.0,
          leading: trackId != null
              ? M3EArtworkLeading(
                  trackId: trackId!,
                  isPlaying: isPlaying,
                )
              : SizedBox(
                  width: 52,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? colorScheme.primaryContainer
                          : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isPlaying
                        ? Icon(
                            FlutterRemix.play_fill,
                            color: colorScheme.primary,
                          )
                        : const Icon(FlutterRemix.music_2_line),
                  ),
                ),
          headline: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          headlineStyle: TextStyle(
            fontSize: 14,
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
            color: isPlaying
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
          supportingText: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isPlaying
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: trailing,
        ),
      ),
    );
  }
}
