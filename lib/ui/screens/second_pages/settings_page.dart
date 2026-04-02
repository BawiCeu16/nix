import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import './settings_details/profile_settings_page.dart';
import './settings_details/appearance_settings_page.dart';
import './settings_details/playback_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          _SectionHeader(title: 'Personalization'),
          CardListTile(
            title: 'Profile',
            subtitle: 'Nickname, avatar, and account info',
            icon: FlutterRemix.user_3_line,
            isFirst: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
            ),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Appearance',
            subtitle: 'Theme, accent colors, and styling',
            icon: FlutterRemix.palette_line,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppearanceSettingsPage()),
            ),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Playback',
            subtitle: 'Gestures, auto-play, and audio settings',
            icon: FlutterRemix.play_circle_line,
            isLast: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlaybackSettingsPage()),
            ),
          ),

          _SectionHeader(title: 'About'),
          CardListTile(
            title: 'Nix Music',
            subtitle: 'Version 1.0.0',
            icon: FlutterRemix.information_line,
            isFirst: true,
            isLast: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
