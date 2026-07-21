import 'package:flutter/material.dart';
import 'package:nix/ui/screens/settings/appearance_settings_page.dart';
import 'package:nix/ui/screens/settings/playback_settings_page.dart';
import 'package:nix/ui/screens/settings/gestures_settings_page.dart';
import 'package:nix/ui/screens/settings/library_settings_page.dart';
import 'package:nix/ui/screens/settings/about_page.dart';

class SettingsPageController extends ChangeNotifier {
  void pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void openAppearance(BuildContext context) {
    pushPage(context, const AppearanceSettingsPage());
  }

  void openPlayback(BuildContext context) {
    pushPage(context, const PlaybackSettingsPage());
  }

  void openGestures(BuildContext context) {
    pushPage(context, const GesturesSettingsPage());
  }

  void openLibrary(BuildContext context) {
    pushPage(context, const LibrarySettingsPage());
  }

  void openAbout(BuildContext context) {
    pushPage(context, const AboutPage());
  }
}
