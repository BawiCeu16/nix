// lib/ui/widgets/recent_and_most.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../providers/music_provider.dart';
import '../pages/recent_plays_screen.dart'; // new page

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
      borderRadius: BorderRadius.circular(10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // artwork (uses on_audio_query widget if available)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 64,
                width: 64,
                child: QueryArtworkWidget(
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
                if ((playCount ?? 0) > 0)
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
                          (playCount ?? 0).toString(),
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
    // Consumer so widget rebuilds when provider notifies (songs / recent changes)
    return Consumer<MusicProvider>(
      builder: (context, music, _) {
        // rawRecentPlays is a list of {"id": int, "ts": int} newest-first
        final raw = music.rawRecentPlays;

        if (raw.isEmpty) return const SizedBox.shrink();

        // Build unique list of song IDs preserving order (latest first)
        final seen = <int>{};
        final ids = <int>[];
        for (var entry in raw) {
          final id = (entry['id'] is int)
              ? entry['id'] as int
              : int.tryParse('${entry['id']}');
          if (id == null) continue;
          if (!seen.contains(id)) {
            seen.add(id);
            ids.add(id);
          }
          if (ids.length >= limit) break;
        }

        // Map ids -> SongModel safely (skip missing songs)
        final songs = <SongModel>[];
        for (var id in ids) {
          final song = music.songs.firstWhere(
            (s) => s.id == id,
            orElse: () => null as SongModel,
          );
          if (song != null) songs.add(song);
        }

        if (songs.isEmpty) return const SizedBox.shrink();

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
                      // navigate to the full Recent Plays page
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecentPlaysScreen(),
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
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, i) {
                  final s = songs[i];
                  return MiniSongTile(
                    song: s,
                    onTap: () {
                      // play + record from list handled via MusicProvider helper
                      Provider.of<MusicProvider>(
                        context,
                        listen: false,
                      ).recordClickAndPlay(s);
                    },
                    playCount: music.getPlayCount(s.id),
                  );
                },
                // separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: songs.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Vertical "most listened" panel - kept for reuse when needed (but Home removed it)
class MostListenedPanel extends StatelessWidget {
  final int limit;
  const MostListenedPanel({super.key, this.limit = 10});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, music, _) {
        // Build (song, count) pairs by scanning loaded songs (safe).
        final pairs = <MapEntry<SongModel, int>>[];
        for (var s in music.songs) {
          final c = music.getPlayCount(s.id);
          if (c > 0) pairs.add(MapEntry(s, c));
        }

        if (pairs.isEmpty) return const SizedBox.shrink();

        pairs.sort((a, b) => b.value.compareTo(a.value)); // desc by count
        final top = pairs.take(limit).map((e) => e.key).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Most listened",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      // navigate to most-listened page (if desired)
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MostListenedScreenPlaceholder(),
                        ),
                      );
                    },
                    child: const Text("See all"),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: top.length,
                shrinkWrap: true,
                // separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final s = top[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: QueryArtworkWidget(
                          id: s.id,
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget: Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Icon(Icons.music_note),
                          ),
                          artworkFit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      s.artist ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text("${music.getPlayCount(s.id)}x"),
                    onTap: () => Provider.of<MusicProvider>(
                      context,
                      listen: false,
                    ).recordClickAndPlay(s),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Placeholder used when pushing from MostListenedPanel -> you should prefer the dedicated screen
class MostListenedScreenPlaceholder extends StatelessWidget {
  const MostListenedScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Most listened')),
      body: const Center(
        child: Text('Use the dedicated Most Listened tab from the bottom nav.'),
      ),
    );
  }
}
