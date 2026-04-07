import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/music_provider.dart';
import '../../../widgets/list_item/card_list_tile.dart';
import '../../../widgets/common/nix_section_header.dart';
import '../../../widgets/dialogs/nix_dialog.dart';

class LibrarySettingsPage extends StatelessWidget {
  const LibrarySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final music = context.read<MusicProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Library Settings'),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          const NixSectionHeader(title: 'Organization', topPadding: 16),
          CardListTile(
            title: 'Filter Short Audio',
            subtitle: _getDurationLabel(settings.minDuration),
            icon: FlutterRemix.filter_line,
            isFirst: true,
            onTap: () => _showFilterDialog(context, settings, music),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Scan Media',
            subtitle: 'Manually refresh your music library',
            icon: FlutterRemix.refresh_line,
            isLast: true,
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanning library...')),
              );
              await music.scanDevice();
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Library scan complete!')),
                );
              }
            },
          ),

          const NixSectionHeader(title: 'Danger Zone', topPadding: 32),
          CardListTile(
            title: 'Reset Library Database',
            subtitle: 'Clear all history, favorites, and re-scan',
            icon: FlutterRemix.delete_bin_line,
            isFirst: true,
            isLast: true,
            onTap: () => _showResetConfirmation(context, music),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 12, top: 24, right: 12),
            child: Text(
              'Use Filter Short Audio to hide ringtones, voice notes, or app sounds. Higher values ensure only your real music shows up.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getDurationLabel(int seconds) {
    if (seconds == 0) return 'OFF';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }

  void _showFilterDialog(
    BuildContext context,
    SettingsProvider settings,
    MusicProvider music,
  ) {
    final options = [0, 30, 60, 120];
    NixDialog.show(
      context: context,
      title: 'Minimum Duration',
      children: options.map((sec) {
        final index = options.indexOf(sec);
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == options.length - 1 ? 0.0 : 2.5,
          ),
          child: CardListTile(
            title: sec == 0 ? 'Off (Show All)' : _getDurationLabel(sec),
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
              settings.setMinDuration(sec);
              // Trigger re-scan to apply filter
              await music.scanDevice();
            },
            trailing: IgnorePointer(
              child: Radio<int>(
                value: sec,
                groupValue: settings.minDuration,
                onChanged: (_) {},
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            isFirst: index == 0,
            isLast: index == options.length - 1,
          ),
        );
      }).toList(),
    );
  }

  void _showResetConfirmation(BuildContext context, MusicProvider music) {
    NixDialog.show(
      context: context,
      title: 'Reset Library?',
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'This will permanently clear your favorites, play counts, and history. The app will then re-scan your device for music.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        CardListTile(
          title: 'Confirm Reset',
          icon: FlutterRemix.check_line,
          isFirst: true,
          onTap: () async {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Resetting library...')),
            );
            await music.resetLibrary();
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Library has been reset.')),
              );
            }
          },
        ),
        const SizedBox(height: 2.5),
        CardListTile(
          title: 'Cancel',
          icon: FlutterRemix.close_line,
          isLast: true,
          onTap: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ],
    );
  }
}
