import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/hive_keys.dart';

enum AccentColorMode { dynamic, device, custom }

/// Manages app-wide settings like theme, accent color, and playback behaviors.
/// Settings are persisted to the Hive.
class SettingsProvider with ChangeNotifier {
  Box get _box => Hive.box(HiveKeys.settingsBox);

  // Auto Play
  /// Whether the player should automatically play the next track or random
  bool get autoPlay => _box.get(HiveKeys.autoPlay, defaultValue: true);

  void setAutoPlay(bool value) {
    _box.put(HiveKeys.autoPlay, value);
    notifyListeners();
  }

  // Theme Mode
  /// The current theme mode (Light, Dark, or System)
  ThemeMode get themeMode {
    final String mode = _box.get(HiveKeys.themeMode, defaultValue: 'system');
    return ThemeMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => ThemeMode.system,
    );
  }

  void setThemeMode(ThemeMode mode) {
    _box.put(HiveKeys.themeMode, mode.name);
    notifyListeners();
  }

  // Accent Color Mode
  /// Defines how the accent color is determined.
  AccentColorMode get accentColorMode {
    final String mode = _box.get(
      HiveKeys.accentColorMode,
      defaultValue: 'dynamic',
    );
    return AccentColorMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => AccentColorMode.dynamic,
    );
  }

  void setAccentColorMode(AccentColorMode mode) {
    _box.put(HiveKeys.accentColorMode, mode.name);
    notifyListeners();
  }

  // Custom Accent Color
  /// The fallback custom accent color when AccentColorMode.custom is used.
  Color get customAccentColor {
    final int colorValue = _box.get(
      HiveKeys.customAccentColor,
      defaultValue: Colors.blue.value,
    );
    return Color(colorValue);
  }

  void setCustomAccentColor(Color color) {
    _box.put(HiveKeys.customAccentColor, color.value);
    notifyListeners();
  }

  // Swipe to Dismiss
  /// Whether the user can dismiss the player by swiping down fully.
  bool get swipeToDismiss =>
      _box.get(HiveKeys.swipeToDismiss, defaultValue: true);

  void setSwipeToDismiss(bool value) {
    _box.put(HiveKeys.swipeToDismiss, value);
    notifyListeners();
  }
}
