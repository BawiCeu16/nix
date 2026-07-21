import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/screens/settings/controllers/library_settings_controller.dart';

class LibrarySettingsPage extends StatefulWidget {
  const LibrarySettingsPage({super.key});

  @override
  State<LibrarySettingsPage> createState() => _LibrarySettingsPageState();
}

class _LibrarySettingsPageState extends State<LibrarySettingsPage> {
  late final LibrarySettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LibrarySettingsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final music = context.read<MusicProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainer,
          appBar: AppBar(
            title: const Text('Library Settings'),
            centerTitle: true,
            scrolledUnderElevation: 0,
            backgroundColor: colorScheme.surfaceContainer,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            physics: const BouncingScrollPhysics(),
            children: [
              const NixSectionHeader(title: 'Organization', topPadding: 16),
              CardListTile(
                title: 'Filter Short Audio',
                subtitle: _controller.getDurationLabel(settings.minDuration),
                icon: FlutterRemix.filter_line,
                isFirst: true,
                onTap: () =>
                    _controller.showFilterDialog(context, settings, music),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Scan Media',
                subtitle: 'Manually refresh your music library',
                icon: FlutterRemix.refresh_line,
                isLast: true,
                onTap: () => _controller.scanDevice(context, music),
              ),
              const NixSectionHeader(title: 'Search & History', topPadding: 32),
              CardListTile(
                title: 'Clear Search History',
                subtitle: 'Delete all previous search queries',
                icon: FlutterRemix.history_line,
                isFirst: true,
                isLast: true,
                onTap: () =>
                    _controller.showClearSearchConfirmation(context, settings),
              ),
              const NixSectionHeader(title: 'Danger Zone', topPadding: 32),
              CardListTile(
                title: 'Reset Library Database',
                subtitle: 'Clear all history, favorites, and re-scan',
                icon: FlutterRemix.delete_bin_line,
                isFirst: true,
                isLast: true,
                onTap: () => _controller.showResetConfirmation(context, music),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 24, right: 12),
                child: Text(
                  'Use Filter Short Audio to hide ringtones, voice notes, or app sounds. Higher values ensure only your real tracks appear in your library.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
              const NixBottomSpacer(),
            ],
          ),
        );
      },
    );
  }
}
