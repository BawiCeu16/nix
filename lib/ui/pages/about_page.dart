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
                  Text(t(context, 'description')),
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
                          children: [
                            //Features
                            TextSpan(
                              text: '${t(context, 'features')} :\n',
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
                              text: '${t(context, 'fea1')} ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '${t(context, 'featu1')}\n'),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '${t(context, 'fea2')} ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '${t(context, 'featu2')}\n'),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '${t(context, 'fea3')} ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '${t(context, 'featu3')}\n'),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '${t(context, 'fea4')} ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '${t(context, 'featu4')}\n'),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '${t(context, 'fea5')} ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '${t(context, 'featu5')}\n'),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '${t(context, 'fea6')} ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '${t(context, 'featu6')}\n'),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '${t(context, 'fea7')} ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '${t(context, 'featu7')}\n'),

                            TextSpan(
                              text: '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '${t(context, 'fea8')} ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '${t(context, 'featu8')}\n'),
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

                        // GitHub Repo
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                          leading: const Icon(FlutterRemix.code_fill),
                          title: Text(t(context, 'source_code_on_gitHub')),
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
                        // Privacy Policy
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                          leading: const Icon(FlutterRemix.shield_line),
                          title: Text(t(context, 'privacy_policy')),
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
                        // Open Source Licenses
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
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
                        const SizedBox(height: 5.0),
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
