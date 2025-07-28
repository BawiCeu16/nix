import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoProvider with ChangeNotifier {
  String _version = '';
  String _appName = '';
  String _packageName = '';

  String get version => _version;
  String get appName => _appName;
  String get packageName => _packageName;

  Future<void> loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    _appName = info.appName;
    _packageName = info.packageName;
    _version = '${info.version} (${info.buildNumber})';
    notifyListeners();
  }
}
