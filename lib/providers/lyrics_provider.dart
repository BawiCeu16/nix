import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLrcLibUrlKey = 'nix_lyric_lib_url';

class LyricSettingsProvider extends ChangeNotifier {
  String _lrcLibBaseUrl = '';
  bool _loaded = false;

  LyricSettingsProvider() {
    _load();
  }

  String get lrcLibBaseUrl => _lrcLibBaseUrl;
  bool get isCustomLrcLibSet => _lrcLibBaseUrl.trim().isNotEmpty;
  bool get loaded => _loaded;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _lrcLibBaseUrl = prefs.getString(_kLrcLibUrlKey) ?? '';
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLrcLibBaseUrl(String url) async {
    final cleaned = _cleanUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLrcLibUrlKey, cleaned);
    _lrcLibBaseUrl = cleaned;
    notifyListeners();
  }

  Future<void> clearLrcLibBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLrcLibUrlKey);
    _lrcLibBaseUrl = '';
    notifyListeners();
  }

  String _cleanUrl(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u;
  }

  bool validateUrl(String url) {
    final cleaned = url.trim();
    if (cleaned.isEmpty) return false;
    final uri = Uri.tryParse(cleaned);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
