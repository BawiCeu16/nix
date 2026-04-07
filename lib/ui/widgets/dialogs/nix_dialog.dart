import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NixDialog extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final int? songId;
  final List<Widget> children;

  const NixDialog({
    super.key,
    this.title,
    this.subtitle,
    this.songId,
    required this.children,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? subtitle,
    int? songId,
    bool useRootNavigator = true,
    required List<Widget> children,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      useRootNavigator: useRootNavigator,
      transitionDuration: Duration(milliseconds: 300),

      pageBuilder: (context, anim1, anim2) {
        return NixDialog(
          title: title,
          subtitle: subtitle,
          songId: songId,
          children: children,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context, rootNavigator: true).pop();
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(28),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withValues(alpha: 0.2),
            //     blurRadius: 20,
            //     offset: const Offset(0, 10),
            //   ),
            // ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      children: [
                        if (songId != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 68,
                              height: 68,
                              child: QueryArtworkWidget(
                                id: songId!,
                                type: ArtworkType.AUDIO,
                                keepOldArtwork: true,
                                artworkFit: BoxFit.cover,
                                artworkBorder: BorderRadius.circular(16),
                                artworkQuality: FilterQuality.high,
                                artworkWidth: 200,
                                artworkHeight: 200,
                                nullArtworkWidget: Container(
                                  color: colorScheme.secondaryContainer,
                                  child: const Icon(FlutterRemix.music_2_line),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title!,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colorScheme.surfaceContainerHigh),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
