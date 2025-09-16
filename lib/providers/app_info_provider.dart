import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppInfoProvider with ChangeNotifier {
  String _version = '';
  String _appName = '';
  String _packageName = '';
  bool _isNewVersion = false; // Internal flag

  String get version => _version;
  String get appName => _appName;
  String get packageName => _packageName;
  bool get isNewVersion => _isNewVersion;

  Future<void> loadAppInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();

    _appName = info.appName;
    _packageName = info.packageName;
    _version = '${info.version} (${info.buildNumber})';

    final lastSeenVersion = prefs.getString('last_seen_version');
    if (lastSeenVersion != _version) {
      _isNewVersion = true;
      await prefs.setString('last_seen_version', _version);
    } else {
      _isNewVersion = false;
    }

    notifyListeners();
  }

  void markUpdateDialogShown() {
    _isNewVersion = false;
    notifyListeners();
  }
}
