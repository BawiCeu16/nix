import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widgets/list_item/card_list_tile.dart';
import '../../../widgets/common/nix_section_header.dart';
import '../../../widgets/common/nix_bottom_spacer.dart';
import '../../../../services/snackbar_service.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          // Hero Section (No Shadow)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          FlutterRemix.music_2_fill,
                          size: 50,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'nix',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  'Version $_version',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          const NixSectionHeader(title: 'Developer', topPadding: 40),
          CardListTile(
            title: 'Bawiceu',
            subtitle: 'Developer & Designer',
            leading: const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/logo.png'),
            ),
            isFirst: true,
            isLast: true,
            onTap: () =>
                _launchURL(context, 'https://bawiceu16.github.io/bawiceu.dev/'),
          ),

          const NixSectionHeader(title: 'Support & Community', topPadding: 32),
          CardListTile(
            title: 'GitHub',
            subtitle: 'Source code and contributions',
            icon: FlutterRemix.github_line,
            isFirst: true,
            onTap: () =>
                _launchURL(context, 'https://github.com/BawiCeu16/nix'),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Telegram',
            subtitle: 'Join our community',
            icon: FlutterRemix.telegram_line,
            onTap: () => _launchURL(context, 'https://t.me/bawiceuapp'),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Report a Bug',
            subtitle: 'Help us improve Nix',
            icon: FlutterRemix.bug_2_line,
            isLast: true,
            onTap: () => _launchURL(context, 'mailto:bawiceu1428@gmail.com'),
          ),

          const NixSectionHeader(title: 'Legal & Tools', topPadding: 32),
          CardListTile(
            title: 'Licenses',
            subtitle: 'Open source libraries used',
            icon: FlutterRemix.scales_3_line,
            isFirst: true,
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'nix',
              applicationVersion: _version,
            ),
          ),
          const SizedBox(height: 2.5),
          CardListTile(
            title: 'Reset to Defaults',
            subtitle: 'Clear all preferences and global settings',
            icon: FlutterRemix.refresh_line,
            isLast: true,
            onTap: () => _showResetDialog(context),
          ),
          const NixBottomSpacer(),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
          'This will revert all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.showSuccessSnackBar('Settings have been reset.');
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
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
}
