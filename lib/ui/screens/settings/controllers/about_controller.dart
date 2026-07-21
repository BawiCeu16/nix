import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/widgets/dialogs/nix_dialog.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/services/snackbar_service.dart';

class AboutPageController extends ChangeNotifier {
  String version = '1.0.0';

  Future<void> initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    version = info.version;
    notifyListeners();
  }

  Future<void> launchURL(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Error opening link: $url');
      }
    }
  }

  void showResetDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    NixDialog.show(
      context: context,
      title: 'Reset to Defaults',
      subtitle: 'This will restore all settings.',
      children: [
        CardListTile(
          title: 'Reset Everything',
          subtitle:
              'All appearance, playback, and library settings will return to their defaults.',
          icon: FlutterRemix.restart_line,
          isFirst: true,
          isLast: true,
          onTap: () {
            settings.resetToDefaults();
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }
}
