import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/%20utils/translator.dart';
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
        title: Text(t(context, 'about')),
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
                          '${t(context, 'version')}: ${appInfo.version}\n${t(context, 'package')}: ${appInfo.packageName}',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    t(context, 'description'),
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 15),

                  const SizedBox(height: 20.0),
                ],
              ),

              // SizedBox(height: 5), // App Info
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Container(
                  // decoration: BoxDecoration(
                  //   border: Border.all(
                  //     width: 2,
                  //     color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  //   ),
                  //   borderRadius: BorderRadius.circular(10),
                  // ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Developer Section
                        Padding(
                          padding: EdgeInsets.only(
                            left: 10,
                            top: 10,
                            bottom: 5,
                          ),
                          child: Text(
                            t(context, 'developer'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        _buildContributorTile(
                          '${t(context, 'developer_name')}',
                          'https://bawiceu16.github.io/bawiceu.dev/',
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

                        // GitHub Repo
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(100),
                          ),
                          leading: const Icon(FlutterRemix.code_fill),
                          title: Text(t(context, 'source_code_on_gitHub')),
                          onTap: () async {
                            launchUrl(
                              Uri.parse('https://github.com/BawiCeu16/nix'),
                            );
                          },
                        ),
                        // Privacy Policy
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(100),
                          ),
                          leading: const Icon(FlutterRemix.shield_line),
                          title: Text(t(context, 'privacy_policy')),
                          onTap: () async {
                            launchUrl(
                              Uri.parse(
                                'https://bawiceu16.github.io/nix-pravicy-and-policy/',
                              ),
                            );
                          },
                        ),
                        // Open Source Licenses
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(100),
                          ),
                          leading: const Icon(Icons.article),
                          title: Text(t(context, 'open_source_licenses')),
                          onTap: () => showLicensePage(
                            context: context,
                            applicationName: appInfo.appName,
                            applicationVersion: appInfo.version,
                            applicationLegalese: '© 2025 Nix',
                          ),
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
        await launchUrl(Uri.parse(url));
      },
    );
  }
}
