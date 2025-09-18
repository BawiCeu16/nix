// lib/ui/pages/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/music_provider.dart';

class FavSettings extends StatelessWidget {
  const FavSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Sync favorites with system playlist'),
            subtitle: const Text(
              'When on, favorites will be exported/kept in Android MediaStore playlist',
            ),
            value: music.favSystemSyncEnabled,
            onChanged: (v) async {
              await context.read<MusicProvider>().setFavoriteSystemSyncEnabled(
                v,
              );
              final snack = v
                  ? 'Favorites will be synced to system playlist'
                  : 'Favorites system sync disabled';
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(snack)));
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Export favorites now'),
            subtitle: const Text(
              'One-tap export current in-app favorites to system playlist (Android only)',
            ),
            trailing: ElevatedButton(
              onPressed: () async {
                try {
                  await context.read<MusicProvider>().exportFavoritesToSystem();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export complete')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              },
              child: const Text('Export'),
            ),
          ),
          if (!Theme.of(
            context,
          ).platform.toString().toLowerCase().contains('android'))
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Note: system playlist export is Android-only (MediaStore).',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
