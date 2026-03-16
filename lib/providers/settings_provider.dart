import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum AccentColorMode { dynamic, device, custom }

class SettingsProvider with ChangeNotifier {
  Box get _box => Hive.box('settings');

  // Auto Play
  bool get autoPlay => _box.get('autoPlay', defaultValue: true);
  set autoPlay(bool value) {
    _box.put('autoPlay', value);
    notifyListeners();
  }

  // Theme Mode
  ThemeMode get themeMode {
    final String mode = _box.get('themeMode', defaultValue: 'system');
    return ThemeMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => ThemeMode.system,
    );
  }

  void setThemeMode(ThemeMode mode) {
    _box.put('themeMode', mode.name);
    notifyListeners();
  }

  // Accent Color Mode
  AccentColorMode get accentColorMode {
    final String mode = _box.get('accentColorMode', defaultValue: 'dynamic');
    return AccentColorMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => AccentColorMode.dynamic,
    );
  }

  void setAccentColorMode(AccentColorMode mode) {
    _box.put('accentColorMode', mode.name);
    notifyListeners();
  }

  // Custom Accent Color
  Color get customAccentColor {
    final int colorValue = _box.get(
      'customAccentColor',
      defaultValue: Colors.blue.value,
    );
    return Color(colorValue);
  }

  void setCustomAccentColor(Color color) {
    _box.put('customAccentColor', color.value);
    notifyListeners();
  }
}
