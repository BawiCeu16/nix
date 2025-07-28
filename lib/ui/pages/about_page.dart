import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/app_info_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appInfo = Provider.of<AppInfoProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        title: Text("About"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: EdgeInsetsGeometry.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(100),
                          child: Image.asset("assets/play_store_512.png"),
                        ),
                        title: Text(
                          appInfo.appName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Version: ${appInfo.version}\nPackage: ${appInfo.packageName}',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    "       Nix is an open-source local music player built with Flutter. It offers a sleek UI, fast performance, and offline playback with features like favorites, shuffle, repeat, theme customization, and a responsive mini-player. Fully free, private, and customizable. Available on GitHub, F-Droid, and coming soon to Play Store.",
                  ),
                  SizedBox(height: 15),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.5,
                          ),
                          children: const [
                            //Features
                            TextSpan(
                              text: 'Features:\n',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Local Music Playback',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: ' –  Plays audio from your device.\n',
                            ),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Favorites Management',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: ' – Easily add/remove favorite tracks.\n',
                            ),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Search & Sort',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  ' – Find songs quickly by name or artist.\n',
                            ),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Shuffle & Repeat',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' – Flexible playback options.\n'),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Custom Themes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: ' – Light/Dark/System + color picker.\n',
                            ),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Responsive MiniPlayer',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: ' – Expandable with smooth animations.\n',
                            ),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Open Source',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  ' – Free, no ads, full transparency on GitHub.\n',
                            ),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Future Releases',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  ' – Officially coming to F-Droid and Google Play.\n',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  /////////////////////////////////////////////////////////////////////////////////////////////
                  const SizedBox(height: 20.0),
                ],
              ),

              // SizedBox(height: 5), // App Info
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Developer Section
                        const Padding(
                          padding: EdgeInsets.only(
                            left: 10,
                            top: 10,
                            bottom: 5,
                          ),
                          child: Text(
                            'Developer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        _buildContributorTile(
                          'BawiCeu',
                          'https://github.com/BawiCeu16',
                          Icon(FlutterRemix.user_2_fill),
                        ),

                        // // Contributors Section
                        // const Padding(
                        //   padding: EdgeInsets.only(
                        //     left: 10,
                        //     top: 10,
                        //     bottom: 5,
                        //   ),
                        //   child: Text(
                        //     'Contributors',
                        //     style: TextStyle(
                        //       fontSize: 18,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),
                        // _buildContributorTile(
                        //   'Open Source Community',
                        //   'https://github.com',
                        //   Icon(FlutterRemix.group_fill),
                        // ),
                        const SizedBox(height: 5.0),

                        Divider(),

                        const SizedBox(height: 5.0),
                        // Check for Updates
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                          leading: const Icon(Icons.update),
                          title: const Text('Check for Updates'),
                          onTap: () async {
                            const githubUrl =
                                'https://github.com/yourusername/nix/releases';
                            if (await canLaunchUrl(Uri.parse(githubUrl))) {
                              await launchUrl(
                                Uri.parse(githubUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                        ),

                        // Open Source Licenses
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                          leading: const Icon(Icons.article),
                          title: const Text('Open Source Licenses'),
                          onTap: () => showLicensePage(
                            context: context,
                            applicationName: appInfo.appName,
                            applicationVersion: appInfo.version,
                            applicationLegalese: '© 2025 Nix Contributors',
                          ),
                        ),

                        const SizedBox(height: 5.0),
                        Divider(),
                        const SizedBox(height: 5.0),

                        // Privacy Policy
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                          leading: const Icon(FlutterRemix.shield_line),
                          title: const Text('Privacy Policy'),
                          onTap: () async {
                            const url =
                                'https://BawiCeu16.github.io/nix/privacy_policy.html';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                        ),

                        // GitHub Repo
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                          leading: const Icon(FlutterRemix.code_fill),
                          title: const Text('Source Code on GitHub'),
                          onTap: () async {
                            const url = 'https://github.com/BawiCeu16/nix';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributorTile(String name, String url, Widget icon) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(100.0),
      ),
      leading: icon,
      title: Text(name),
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
