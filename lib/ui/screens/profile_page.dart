import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/tiles/track_tile.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/common/nix_scrollbar.dart';
import 'package:nix/ui/screens/controllers/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfilePageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfilePageController();
    final user = context.read<UserProvider>();
    _controller.init(user);
  }

  @override
  void dispose() {
    _controller.disposeController();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = context.watch<UserProvider>();
    final music = context.watch<MusicProvider>();

    final activeAvatarIndex = _controller.isEditing
        ? _controller.tempAvatarIndex
        : user.avatarIndex;
    final avatarColor = UserProvider.avatarColors[activeAvatarIndex];
    final avatarIcon = UserProvider.avatarIcons[activeAvatarIndex];
    final topTracks = music.topPlayed.tracks.take(5).toList();

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainer,
          appBar: AppBar(
            backgroundColor: colorScheme.surfaceContainer,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text('Profile'),
            centerTitle: true,
            actions: [
              if (!_controller.isEditing)
                IconButton(
                  icon: const Icon(FlutterRemix.edit_line),
                  onPressed: () => _controller.startEditing(user),
                )
              else
                IconButton(
                  icon: const Icon(FlutterRemix.check_line),
                  onPressed: () => _controller.saveEditing(context),
                ),
            ],
          ),
          body: NixScrollbar(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Avatar with Badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: avatarColor.withValues(alpha: 0.2),
                        child: Icon(avatarIcon, size: 54, color: avatarColor),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: colorScheme.primary,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _controller.showAvatarPickerDialog(
                              context,
                              user,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                FlutterRemix.camera_line,
                                size: 18,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // User Display Name / Edit Input
                  if (!_controller.isEditing) ...[
                    Text(
                      user.userName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Music Enthusiast',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _controller.nameController,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter name',
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ExpressiveToneButton(
                          onPressed: _controller.cancelEditing,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ExpressiveToneButton(
                          onPressed: () => _controller.saveEditing(context),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: FlutterRemix.music_2_line,
                          title: 'Tracks',
                          value: '${music.tracks.length}',
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: FlutterRemix.disc_line,
                          title: 'Albums',
                          value: '${music.albums.length}',
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: FlutterRemix.user_4_line,
                          title: 'Artists',
                          value: '${music.artists.length}',
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Top Tracks Section
                  const NixSectionHeader(title: 'Most Listened Tracks', topPadding: 0),
                  const SizedBox(height: 12),

                  if (topTracks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Start playing music to build your stats!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: topTracks.length,
                      itemBuilder: (context, index) {
                        final track = topTracks[index];
                        return TrackTile(
                          track: track,
                          playlistContext: topTracks,
                          isFirst: index == 0,
                          isLast: index == topTracks.length - 1,
                        );
                      },
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
