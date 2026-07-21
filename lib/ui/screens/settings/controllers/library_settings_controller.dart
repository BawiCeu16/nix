import 'package:flutter/material.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/buttons/expressive_button.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/services/snackbar_service.dart';
import 'package:flutter_remix/flutter_remix.dart';

class LibrarySettingsController extends ChangeNotifier {
  String getDurationLabel(int seconds) {
    if (seconds == 0) return 'OFF';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }

  Future<void> scanDevice(BuildContext context, MusicProvider music) async {
    context.showInfoSnackBar('Scanning library...');
    await music.scanDevice();
    if (context.mounted) {
      context.showSuccessSnackBar('Library scan complete!');
    }
  }

  void showFilterDialog(
    BuildContext context,
    SettingsProvider settings,
    MusicProvider music,
  ) {
    final options = [0, 30, 60, 120];
    NixDialog.show(
      context: context,
      title: 'Filter Tracks',
      children: [
        RadioGroup<int>(
          groupValue: settings.minDuration,
          onChanged: (sec) async {
            if (sec != null) {
              Navigator.of(context, rootNavigator: true).pop();
              settings.setMinDuration(sec);
              await music.scanDevice();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((sec) {
              final index = options.indexOf(sec);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == options.length - 1 ? 0.0 : 2.5,
                ),
                child: CardListTile(
                  title: sec == 0 ? 'Off (Show All)' : getDurationLabel(sec),
                  onTap: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    settings.setMinDuration(sec);
                    await music.scanDevice();
                  },
                  trailing: IgnorePointer(
                    child: Radio<int>(
                      value: sec,
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  isFirst: index == 0,
                  isLast: index == options.length - 1,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void showClearSearchConfirmation(
    BuildContext context,
    SettingsProvider settings,
  ) {
    NixDialog.show(
      context: context,
      title: 'Clear Search History?',
      subtitle: 'Remove all search history?',
      children: [
        Builder(
          builder: (dialogContext) {
            return Row(
              children: [
                Expanded(
                  child: ExpressiveToneButton(
                    onPressed: () =>
                        Navigator.of(dialogContext, rootNavigator: true).pop(),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ExpressiveButton(
                    onPressed: () {
                      settings.clearSearchHistory();
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                    },
                    child: const Text("Clear"),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void showResetConfirmation(BuildContext context, MusicProvider music) {
    NixDialog.show(
      context: context,
      title: 'Reset Library?',
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'This will permanently clear your favorites, play counts, and history. Your device will then be re-scanned for tracks.',
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
            context.showInfoSnackBar('Resetting library...');
            await music.resetLibrary();
            if (context.mounted) {
              context.showSuccessSnackBar('Library has been reset.');
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
