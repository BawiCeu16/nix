import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _nameController = TextEditingController(text: user.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final music = context.watch<MusicProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: colorScheme.surfaceContainer,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? FlutterRemix.check_line : FlutterRemix.pencil_line,
            ),
            onPressed: () {
              if (_isEditing) {
                if (_nameController.text.trim().isNotEmpty) {
                  user.setUserName(_nameController.text.trim());
                } else {
                  _nameController.text = user.userName;
                }
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 12),
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: UserProvider.avatarColors[user.avatarIndex]
                      .withValues(alpha: 0.2),
                  child: Icon(
                    UserProvider.avatarIcons[user.avatarIndex],
                    color: UserProvider.avatarColors[user.avatarIndex],
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                _isEditing
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(100),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        user.userName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(label: 'Songs', value: music.songs.length.toString()),
              _StatItem(label: 'Albums', value: music.albums.length.toString()),
              _StatItem(
                label: 'Artists',
                value: music.artists.length.toString(),
              ),
            ],
          ),

          const SizedBox(height: 32),

          if (music.topPlayed.songs.isNotEmpty) ...[
            const _SectionHeader(title: 'TOP LISTENED'),
            const SizedBox(height: 8),
            ...List.generate(music.topPlayed.songs.take(5).length, (index) {
              final song = music.topPlayed.songs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 2.5),
                child: CardListTile(
                  title: song.title,
                  subtitle: song.artist,
                  icon: FlutterRemix.music_2_line,
                  isFirst: index == 0,
                  isLast: index == music.topPlayed.songs.take(5).length - 1,
                  onTap: () {
                    context.read<CurrentMusicProvider>().playSong(
                      song,
                      playlist: music.topPlayed,
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          if (music.recentlyPlayed.songs.isNotEmpty) ...[
            const _SectionHeader(title: 'RECENTLY LISTENED'),
            const SizedBox(height: 8),
            ...List.generate(music.recentlyPlayed.songs.take(5).length, (
              index,
            ) {
              final song = music.recentlyPlayed.songs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 2.5),
                child: CardListTile(
                  title: song.title,
                  subtitle: song.artist,
                  icon: FlutterRemix.time_line,
                  isFirst: index == 0,
                  isLast:
                      index == music.recentlyPlayed.songs.take(5).length - 1,
                  onTap: () {
                    context.read<CurrentMusicProvider>().playSong(
                      song,
                      playlist: music.recentlyPlayed,
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
