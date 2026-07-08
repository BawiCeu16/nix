import 'package:flutter/material.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:nix/ui/widgets/common/nix_artwork.dart';
import 'package:nix/models/settings/artwork_quality.dart';

class NixDialog extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final int? trackId;
  final CrossAxisAlignment titleAlignment;
  final List<Widget> children;

  const NixDialog({
    super.key,
    this.title,
    this.subtitle,
    this.trackId,
    this.titleAlignment = CrossAxisAlignment.center,
    required this.children,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? subtitle,
    int? trackId,
    CrossAxisAlignment titleAlignment = CrossAxisAlignment.center,
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
          trackId: trackId,
          titleAlignment: titleAlignment,
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
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(28),
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
                        if (trackId != null) ...[
                          SizedBox(
                            width: 68,
                            height: 68,
                            child: NixArtwork(
                              id: trackId!,
                              type: ArtworkType.AUDIO,
                              borderRadius: BorderRadius.circular(16),
                              width: 68,
                              height: 68,
                              quality: NixArtworkQuality
                                  .medium, // Dialog headers need crisp art
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: titleAlignment,
                            children: [
                              Text(
                                title!,
                                textAlign:
                                    titleAlignment == CrossAxisAlignment.center
                                    ? TextAlign.center
                                    : TextAlign.start,
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
                                  textAlign:
                                      titleAlignment ==
                                          CrossAxisAlignment.center
                                      ? TextAlign.center
                                      : TextAlign.start,
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
