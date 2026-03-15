import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';

class TopBar extends StatelessWidget {
  final double topRowOpacity;
  final double bounceProgressValue;
  final Color onSecondary;
  final VoidCallback onSnapToMini;

  const TopBar({
    super.key,
    required this.topRowOpacity,
    required this.bounceProgressValue,
    required this.onSecondary,
    required this.onSnapToMini,
  });

  @override
  Widget build(BuildContext context) {
    final currentMusic = context.watch<CurrentMusicProvider>();
    final playlistName = currentMusic.currentPlaylist?.name ?? '';

    return Material(
      type: MaterialType.transparency,
      child: Opacity(
        opacity: topRowOpacity,
        child: Transform.translate(
          offset: Offset(0, (1 - bounceProgressValue) * -100),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: onSnapToMini,
                    icon: Icon(Icons.keyboard_arrow_down, color: onSecondary),
                    iconSize: 26.0,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Playing from",
                          style: TextStyle(
                            color: onSecondary.withValues(alpha: .8),
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          playlistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20.0,
                            color: onSecondary.withValues(alpha: .9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: .2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.more_horiz, color: onSecondary),
                    ),
                    iconSize: 26.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
