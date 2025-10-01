import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nix/%20utils/translator.dart';
import 'package:nix/ui/pages/Language_selection_screen.dart';
import 'package:nix/ui/pages/about_page.dart';
import 'package:nix/ui/pages/lyric_settings_page.dart';
import 'package:nix/ui/pages/theme_setting_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  void updateSystemOverlayStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    SystemChrome.setSystemUIOverlayStyle(
      brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.black,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.white,
            ),
    );
  }

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        title: Text(t(context, 'settings')),
        centerTitle: true,
      ),

      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 400 ? 400 : double.infinity,
          ),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            child: Column(
              children: [
                Expanded(
                  child: SizedBox(
                    child: ListView(
                      children: [
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Text(
                            t(context, 'settings'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(height: 5),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              //Appearance
                              Card(
                                margin: EdgeInsets.all(0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                    bottomLeft: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(t(context, 'appearance')),
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Icon(FlutterRemix.palette_fill),
                                  ),
                                  trailing: Icon(
                                    FlutterRemix.arrow_right_s_line,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                      bottomLeft: Radius.circular(5),
                                      bottomRight: Radius.circular(5),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ThemeSettingsPage(),
                                      ),
                                    );
                                    // Navigator.push(
                                    //   context,
                                    //   PageAnimationTransition(
                                    //     page: ThemeSettingsPage(),
                                    //     pageAnimationType:
                                    //         RightToLeftTransition(),
                                    //   ),
                                    // );
                                  },
                                ),
                              ),
                              SizedBox(height: 3),
                              //Language
                              Card(
                                margin: EdgeInsets.all(0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5),
                                    bottomLeft: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(t(context, 'language')),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(5),
                                      bottomLeft: Radius.circular(5),
                                      bottomRight: Radius.circular(5),
                                    ),
                                  ),
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Icon(FlutterRemix.global_line),
                                  ),
                                  trailing: Icon(
                                    FlutterRemix.arrow_right_s_line,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LanguageSelectionScreen(),
                                    ),
                                  ),

                                  //  Navigator.push(
                                  //   context,
                                  //   PageAnimationTransition(
                                  //     page: LanguageSelectionScreen(),
                                  //     pageAnimationType:
                                  //         RightToLeftTransition(),
                                  //   ),
                                  // ),
                                ),
                              ),

                              SizedBox(height: 3),
                              //lyrics settings
                              Card(
                                margin: EdgeInsets.all(0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5),
                                    bottomLeft: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(t(context, 'lyrics_settings')),

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(5),
                                      bottomLeft: Radius.circular(5),
                                      bottomRight: Radius.circular(5),
                                    ),
                                  ),
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Icon(Icons.lyrics),
                                  ),
                                  trailing: Icon(
                                    FlutterRemix.arrow_right_s_line,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LyricSettingsPage(),
                                    ),
                                  ),

                                  //  Navigator.push(
                                  //   context,
                                  //   PageAnimationTransition(
                                  //     page: LanguageSelectionScreen(),
                                  //     pageAnimationType:
                                  //         RightToLeftTransition(),
                                  //   ),
                                  // ),
                                ),
                              ),

                              SizedBox(height: 3),

                              //delete data's
                              Card(
                                margin: EdgeInsets.all(0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5),
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                ),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(5),
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  title: Text(
                                    t(context, 'clear_data'),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Icon(
                                      FlutterRemix.delete_bin_5_fill,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                          t(context, 'warning'),
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        ),
                                        content: Wrap(
                                          children: [
                                            Text(
                                              t(context, 'delete_warning_msg'),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          SizedBox(
                                            height: 40,
                                            child: FilledButton.tonal(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(t(context, 'cancel')),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 40,
                                            child: FilledButton(
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    WidgetStateProperty.all(
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                    ),
                                              ),
                                              onPressed: () {},
                                              child: Text(t(context, 'delete')),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        //links////////////////////////////////////////////////////////////////////////////////////
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Text(
                            t(context, 'more'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(height: 5),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),

                          child: Column(
                            children: [
                              //Github
                              Card(
                                margin: EdgeInsets.all(0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                    bottomLeft: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(t(context, 'dev_github')),
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Icon(FontAwesomeIcons.github),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                      bottomLeft: Radius.circular(5),
                                      bottomRight: Radius.circular(5),
                                    ),
                                  ),
                                  onTap: () {
                                    launchUrl(
                                      Uri.parse("https://github.com/BawiCeu16"),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 3),
                              //Email
                              Card(
                                margin: EdgeInsets.all(0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5),
                                    bottomLeft: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(t(context, 'email')),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(5),
                                      bottomLeft: Radius.circular(5),
                                      bottomRight: Radius.circular(5),
                                    ),
                                  ),
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Icon(Icons.email),
                                  ),
                                  onTap: () {
                                    launchUrl(
                                      Uri.parse("mailto:bawiceu1428@gmail.com"),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 3),
                              //About
                              Card(
                                margin: EdgeInsets.all(0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5),
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(t(context, 'about')),
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Icon(FlutterRemix.information_fill),
                                  ),
                                  trailing: Icon(
                                    FlutterRemix.arrow_right_s_line,
                                  ),

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(5),
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => InfoPage(),
                                      ),
                                    );

                                    // Navigator.push(
                                    //   context,
                                    //   PageAnimationTransition(
                                    //     page: InfoPage(),
                                    //     pageAnimationType:
                                    //         RightToLeftTransition(),
                                    //   ),
                                    // );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
