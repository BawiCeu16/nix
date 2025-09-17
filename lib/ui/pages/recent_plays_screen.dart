// lib/ui/pages/recent_plays_screen.dart
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';

class RecentPlaysScreen extends StatelessWidget {
  const RecentPlaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = Provider.of<MusicProvider>(context);
    final recent = music.getRecentlyPlayed(limit: 200);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently played'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await music.clearRecentPlays();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recent plays cleared')),
              );
            },
          ),
        ],
      ),
      body: recent.isEmpty
          ? Center(
              child: Text(
                'No recent plays',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              itemCount: recent.length,
              // separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final s = recent[i];
                return ListTile(
                  leading: QueryArtworkWidget(
                    keepOldArtwork: true,
                    id: s.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: const Icon(Icons.music_note),
                    ),
                  ),
                  title: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(s.artist ?? ''),
                  trailing: Text('${music.getPlayCount(s.id)}x'),
                  onTap: () {
                    // record the click (so counts reflect clicks from this list) and play
                    music.recordClickAndPlay(s);
                  },
                  onLongPress: () {
                    // maybe show details dialog (reuse existing dialog)
                    // showDialog(context: context, builder: (_) => SongDetailsDialog(song: s));
                  },
                );
              },
            ),
    );
  }
}
