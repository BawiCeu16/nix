import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/screens/second_pages/settings_details/about_page.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'profile_page.dart';
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
          const NixSectionHeader(
            title: 'Personalization Settings',
            topPadding: 12,
          ),
          CardListTile(
            title: 'Profile',
            subtitle: 'Nickname, avatar, and account info',
            icon: FlutterRemix.user_3_line,
            isFirst: true,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
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

          const NixSectionHeader(title: 'About', topPadding: 32),
          CardListTile(
            title: 'About nix',
            subtitle: 'Info, version and more.',
            icon: FlutterRemix.information_line,
            isFirst: true,
            isLast: true,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AboutPage())),
          ),
        ],
      ),
    );
  }
}
