import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/screens/settings/about_page.dart';
import 'package:nix/ui/screens/settings/library_settings_page.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/screens/settings/appearance_settings_page.dart';
import 'package:nix/ui/screens/settings/gestures_settings_page.dart';
import 'package:nix/ui/screens/settings/playback_settings_page.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          const NixSectionHeader(title: 'General Settings', topPadding: 12),
          CardListTile(
            title: 'Appearance',
            subtitle: 'Theme, accent colors, and styling',
            icon: FlutterRemix.palette_line,
            isFirst: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppearanceSettingsPage()),
            ),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Playback',
            subtitle: 'Auto-play, silence trimmers, and behavior',
            icon: FlutterRemix.play_circle_line,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlaybackSettingsPage()),
            ),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Gestures & Interface',
            subtitle: 'Swipes, haptic feedback, and notifications',
            icon: FlutterRemix.fingerprint_line,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GesturesSettingsPage()),
            ),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Library',
            subtitle: 'Organize your collection and filter audio',
            icon: FlutterRemix.music_line,
            isLast: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LibrarySettingsPage()),
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
          const NixBottomSpacer(),
        ],
      ),
    );
  }
}
