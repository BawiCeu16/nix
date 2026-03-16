import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:hive/hive.dart';

class QueueTile extends StatelessWidget {
  const QueueTile({
    super.key,
    this.title = "Queue Track",
    this.subtitle = "Queue Artist",
    this.songUri,
    this.itemIndex = 0,
    this.isPlaying = false,
    this.onTap,
    this.onRemove,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? songUri;
  final int itemIndex;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Fetch artwork from Hive
    Uint8List? artwork;
    try {
      if (songUri != null && Hive.isBoxOpen('cached_images')) {
        final data = Hive.box('cached_images').get(songUri);
        if (data != null && data is Uint8List) artwork = data;
      }
    } catch (_) {}

    return Material(
      type: MaterialType.transparency,
      child: Dismissible(
        key: ValueKey('queue_${itemIndex}_$title'),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            onRemove?.call();
            return true;
          }
          return false;
        },
        direction: DismissDirection.endToStart,
        background: Container(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Remove',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    FlutterRemix.delete_bin_line,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ],
              ),
            ),
          ),
        ),
        movementDuration: const Duration(milliseconds: 50),
        resizeDuration: const Duration(milliseconds: 50),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: artwork != null
                  ? Image.memory(artwork, fit: BoxFit.cover)
                  : Container(
                      color: isPlaying
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.secondaryContainer,
                      child: isPlaying
                          ? Icon(
                              FlutterRemix.play_fill,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : const Icon(FlutterRemix.music_2_line),
                    ),
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
          ),
          visualDensity: VisualDensity.compact,
          onTap: onTap,
          trailing:
              trailing ??
              Icon(
                FlutterRemix.menu_line,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
        ),
      ),
    );
  }
}
