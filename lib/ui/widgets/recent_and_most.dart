// ui/widgets/recent_and_most.dart
import 'package:flutter/material.dart';
import 'package:nix/ui/pages/recent_plays_screen.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../providers/music_provider.dart';

/// Small reusable tile used by both lists
class MiniSongTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final int? playCount;

  const MiniSongTile({
    super.key,
    required this.song,
    this.onTap,
    this.playCount,
  });

  @override
  Widget build(BuildContext context) {
    // Minimal M3 card-like tile
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // artwork (uses on_audio_query widget if available)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 64,
                width: 104,
                child: QueryArtworkWidget(
                  keepOldArtwork: true,
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Center(
                      child: Icon(
                        Icons.music_note,
                        size: 28,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  artworkFit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                song.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (song.artist ?? 'Unknown'),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                if (playCount != null)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.whatshot, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          playCount.toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal recently played strip
class RecentlyPlayedStrip extends StatelessWidget {
  final int limit;
  const RecentlyPlayedStrip({super.key, this.limit = 12});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, music, _) {
        final recents = music.getRecentlyPlayed(limit: limit);
        if (recents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recently played",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      // show more: simple sheet listing recent (stateless)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecentPlaysScreen(),
                        ),
                      );
                    },
                    child: const Text("See all"),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.separated(
                physics: BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, i) {
                  final s = recents[i];
                  return MiniSongTile(
                    song: s,
                    onTap: () => music.playSong(s),
                    playCount: music.getPlayCount(s.id),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: recents.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

// /// Vertical "most listened" panel
// class MostListenedPanel extends StatelessWidget {
//   final int limit;
//   const MostListenedPanel({super.key, this.limit = 10});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<MusicProvider>(
//       builder: (context, music, _) {
//         final top = music.getMostListened(limit: limit);
//         if (top.isEmpty) return const SizedBox.shrink();

//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Most listened",
//                     style: Theme.of(context).textTheme.titleMedium,
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       // maybe navigate to a longer screen
//                       showModalBottomSheet(
//                         context: context,
//                         builder: (_) => _MostFullSheet(),
//                       );
//                     },
//                     child: const Text("See all"),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//               ListView.builder(
//                 itemCount: top.length,
//                 shrinkWrap: true,
//                 physics: BouncingScrollPhysics(),
//                 itemBuilder: (context, i) {
//                   final s = top[i];
//                   return ListTile(
//                     leading: ClipRRect(
//                       borderRadius: BorderRadius.circular(6),
//                       child: SizedBox(
//                         width: 48,
//                         height: 48,
//                         child: QueryArtworkWidget(
//                           id: s.id,
//                           type: ArtworkType.AUDIO,
//                           nullArtworkWidget: Container(
//                             color: Theme.of(context).colorScheme.surface,
//                             child: const Icon(Icons.music_note),
//                           ),
//                           artworkFit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                     title: Text(
//                       s.title,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     subtitle: Text(
//                       s.artist ?? 'Unknown',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     trailing: Text("${music.getPlayCount(s.id)}x"),
//                     onTap: () => Provider.of<MusicProvider>(
//                       context,
//                       listen: false,
//                     ).playSong(s),
//                   );
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// /// Small sheets for "See all" (stateless)
// class _RecentFullSheet extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final music = Provider.of<MusicProvider>(context, listen: false);
//     final recents = music.getRecentlyPlayed(limit: 200);
//     return SafeArea(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 12),
//           Text(
//             "Recently played",
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//           const SizedBox(height: 8),
//           Flexible(
//             child: ListView.separated(
//               physics: BouncingScrollPhysics(),
//               shrinkWrap: true,
//               itemCount: recents.length,
//               separatorBuilder: (_, __) => const Divider(),
//               itemBuilder: (context, i) {
//                 final s = recents[i];
//                 return ListTile(
//                   leading: QueryArtworkWidget(
//                     keepOldArtwork: true,
//                     id: s.id,
//                     type: ArtworkType.AUDIO,
//                     nullArtworkWidget: Container(
//                       color: Theme.of(context).colorScheme.surface,
//                       child: const Icon(Icons.music_note),
//                     ),
//                   ),
//                   title: Text(s.title),
//                   subtitle: Text(s.artist ?? ''),
//                   onTap: () {
//                     music.playSong(s);
//                     Navigator.of(context).pop();
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MostFullSheet extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final music = Provider.of<MusicProvider>(context, listen: false);
//     final top = music.getMostListened(limit: 200);
//     return SafeArea(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 12),
//           Text("Most listened", style: Theme.of(context).textTheme.titleLarge),
//           const SizedBox(height: 8),
//           Flexible(
//             child: ListView.separated(
//               shrinkWrap: true,
//               itemCount: top.length,
//               separatorBuilder: (_, __) => const Divider(),
//               itemBuilder: (context, i) {
//                 final s = top[i];
//                 return ListTile(
//                   leading: QueryArtworkWidget(
//                     keepOldArtwork: true,
//                     id: s.id,
//                     type: ArtworkType.AUDIO,
//                     nullArtworkWidget: Container(
//                       color: Theme.of(context).colorScheme.surface,
//                       child: const Icon(Icons.music_note),
//                     ),
//                   ),
//                   title: Text(s.title),
//                   subtitle: Text(
//                     "${s.artist ?? ''} • ${music.getPlayCount(s.id)} plays",
//                   ),
//                   onTap: () {
//                     music.playSong(s);
//                     Navigator.of(context).pop();
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
