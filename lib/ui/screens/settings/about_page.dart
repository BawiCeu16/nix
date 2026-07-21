import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/ui/widgets/common/nix_section_header.dart';
import 'package:nix/ui/widgets/common/nix_bottom_spacer.dart';
import 'package:nix/ui/screens/settings/controllers/about_controller.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final AboutPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AboutPageController()..initPackageInfo();
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
                      'Version ${_controller.version}',
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
                leading: const Icon(FlutterRemix.user_4_line),
                isFirst: true,
                isLast: true,
                onTap: () => _controller.launchURL(
                  context,
                  'https://bawiceu16.github.io/bawiceu.dev/',
                ),
              ),

              const NixSectionHeader(title: 'Support & Community', topPadding: 32),
              CardListTile(
                title: 'GitHub',
                subtitle: 'Source code and contributions',
                icon: FlutterRemix.github_line,
                isFirst: true,
                onTap: () => _controller.launchURL(
                  context,
                  'https://github.com/BawiCeu16/nix',
                ),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Telegram',
                subtitle: 'Join our community',
                icon: FlutterRemix.telegram_line,
                onTap: () => _controller.launchURL(
                  context,
                  'https://t.me/bawiceuapp',
                ),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Report a Bug',
                subtitle: 'Help us improve Nix',
                icon: FlutterRemix.bug_2_line,
                isLast: true,
                onTap: () => _controller.launchURL(
                  context,
                  'mailto:bawiceu1428@gmail.com',
                ),
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
                  applicationVersion: _controller.version,
                ),
              ),
              const SizedBox(height: 2.5),
              CardListTile(
                title: 'Reset to Defaults',
                subtitle: 'Clear all preferences and global settings',
                icon: FlutterRemix.refresh_line,
                isLast: true,
                onTap: () => _controller.showResetDialog(context),
              ),
              const NixBottomSpacer(),
            ],
          ),
        );
      },
    );
  }
}
