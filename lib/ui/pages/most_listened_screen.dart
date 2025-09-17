// lib/ui/pages/most_listened_screen.dart
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../widgets/recent_and_most.dart';

class MostListenedScreen extends StatelessWidget {
  const MostListenedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = Provider.of<MusicProvider>(context);
    final top = music.getMostListened(limit: 200);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        title: const Text('Most listened'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset counts',
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Reset play counts?'),
                  content: const Text(
                    'This will clear all play counts. Are you sure?',
                  ),
                  actions: [
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await music.resetPlayCounts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Play counts reset')),
                );
              }
            },
          ),
        ],
      ),
      body: top.isEmpty
          ? Center(
              child: Text(
                'No play counts yet',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              itemCount: top.length,
              // separatorBuilder: (_, __) => const Divider(height: 0),
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, i) {
                final s = top[i];
                return ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: QueryArtworkWidget(
                      keepOldArtwork: true,
                      id: s.id,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: const Icon(Icons.music_note),
                      ),
                    ),
                  ),
                  title: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(s.artist ?? ''),
                  trailing: Text('${music.getPlayCount(s.id)}x'),
                  onTap: () => music.recordClickAndPlay(s),
                );
              },
            ),
    );
  }
}
