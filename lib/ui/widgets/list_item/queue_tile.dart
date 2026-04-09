import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../common/nix_artwork.dart';

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
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        key: ValueKey('queue_${itemIndex}_$title'),
        leading: SizedBox(
          width: 48,
          height: 48,
          child: trackId != null
              ? NixArtwork(
                  id: trackId!,
                  type: ArtworkType.AUDIO,
                  width: 48,
                  height: 48,
                )
              : Container(
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isPlaying
                      ? Icon(
                          FlutterRemix.play_fill,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(FlutterRemix.music_2_line),
                ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: isPlaying
              ? TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        visualDensity: VisualDensity.compact,
        onTap: onTap,
        trailing: trailing,
      ),
    );
  }
}
