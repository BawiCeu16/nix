import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      resizeToAvoidBottomInset: false,
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
                GestureDetector(
                  onTap: _isEditing
                      ? () => _showAvatarPicker(context, user)
                      : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: UserProvider
                            .avatarColors[user.avatarIndex]
                            .withValues(alpha: 0.2),
                        child: Icon(
                          UserProvider.avatarIcons[user.avatarIndex],
                          color: UserProvider.avatarColors[user.avatarIndex],
                          size: 50,
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              FlutterRemix.pencil_fill,
                              size: 16,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
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
                          onSubmitted: (_) {
                            if (_nameController.text.trim().isNotEmpty) {
                              context.read<UserProvider>().setUserName(
                                _nameController.text.trim(),
                              );
                            }
                            setState(() => _isEditing = false);
                          },
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
            const NixSectionHeader(title: 'Top Listened', topPadding: 32),
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
            const NixSectionHeader(title: 'Recently Listened', topPadding: 32),
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

          // Fix for keyboard top bar behavior (SearchPage style)
          SizedBox(height: 120 + keyboardHeight),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, UserProvider user) {
    NixDialog.show(
      context: context,
      title: 'Select Avatar',
      children: List.generate(UserProvider.avatarIcons.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == UserProvider.avatarIcons.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: 'Avatar ${index + 1}',
            icon: UserProvider.avatarIcons[index],
            trailing: user.avatarIndex == index
                ? Icon(
                    FlutterRemix.check_line,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            isFirst: index == 0,
            isLast: index == UserProvider.avatarIcons.length - 1,
            onTap: () {
              user.setAvatarIndex(index);
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
        );
      }),
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
        const SizedBox(height: 4),
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
