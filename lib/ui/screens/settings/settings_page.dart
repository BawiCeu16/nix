import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/screens/settings/controllers/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsPageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
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
                onTap: () => _controller.openAppearance(context),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Playback',
                subtitle: 'Auto-play, silence trimmers, and behavior',
                icon: FlutterRemix.play_circle_line,
                onTap: () => _controller.openPlayback(context),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Gestures & Interface',
                subtitle: 'Swipes, haptic feedback, and notifications',
                icon: FlutterRemix.fingerprint_line,
                onTap: () => _controller.openGestures(context),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Library',
                subtitle: 'Organize your collection and filter audio',
                icon: FlutterRemix.music_line,
                isLast: true,
                onTap: () => _controller.openLibrary(context),
              ),
              const NixSectionHeader(title: 'About', topPadding: 32),
              CardListTile(
                title: 'About nix',
                subtitle: 'Info, version and more.',
                icon: FlutterRemix.information_line,
                isFirst: true,
                isLast: true,
                onTap: () => _controller.openAbout(context),
              ),
              const NixBottomSpacer(),
            ],
          ),
        );
      },
    );
  }
}
