import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../widgets/list_item/card_list_tile.dart';
import '../../../widgets/common/nix_section_header.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          final version = info?.version ?? '1.0.0';

          return ListView(
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 0),
                    Text(
                      'Version $version',
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
                subtitle: 'Lead Developer & Designer',
                icon: FlutterRemix.code_s_slash_line,
                isFirst: true,
                isLast: true,
                onTap: () {}, // Could link to a profile
              ),

              const NixSectionHeader(
                title: 'Support & Community',
                topPadding: 32,
              ),
              CardListTile(
                title: 'GitHub',
                subtitle: 'Source code and contributions',
                icon: FlutterRemix.github_line,
                isFirst: true,
                onTap: () {},
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Telegram',
                subtitle: 'Join our community',
                icon: FlutterRemix.telegram_line,
                onTap: () {},
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Report a Bug',
                subtitle: 'Help us improve Nix',
                icon: FlutterRemix.bug_2_line,
                isLast: true,
                onTap: () {},
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
                  applicationVersion: version,
                ),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Reset to Defaults',
                subtitle: 'Clear all settings and preferences',
                icon: FlutterRemix.refresh_line,
                isLast: true,
                onTap: () => _showResetDialog(context),
              ),
              const SizedBox(height: 14),
            ],
          );
        },
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
              // Note: Ideally, clear Hive boxes here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings have been reset.')),
              );
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
}
