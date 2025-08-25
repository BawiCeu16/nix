import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.blue;
  bool _isMonochrome = false;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get isMonochrome => _isMonochrome;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
    final colorValue = prefs.getInt('seedColor');
    if (colorValue != null) _seedColor = Color(colorValue);
    _isMonochrome = prefs.getBool('isMonochrome') ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', color.value);
  }

  Future<void> setMonochromeEnabled(bool enabled) async {
    _isMonochrome = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMonochrome', enabled);
  }

  // ---------- MONOCHROME PALETTES (explicit greys) ----------
  // Light monochrome palette (no color)
  ColorScheme _monochromeLightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF111111), // dark primary
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF444444),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFB00020),
      onError: Color(0xFFFFFFFF),
      background: Color(0xFFFFFFFF), // pure white background
      onBackground: Color(0xFF000000),
      surface: Color(0xFFF2F2F2), // very light surface
      onSurface: Color(0xFF000000),
      primaryContainer: Color(0xFF222222),
      onPrimaryContainer: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF666666),
      onSecondaryContainer: Color(0xFFFFFFFF),
      surfaceVariant: Color(0xFFEAEAEA),
      outline: Color(0xFFBBBBBB),
      shadow: Color(0xFF000000),
      inverseSurface: Color(0xFF1A1A1A),
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFFEEEEEE),
    );
  }

  // Dark monochrome palette (no color)
  ColorScheme _monochromeDarkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFFFFFF), // white primary for dark mode
      onPrimary: Color(0xFF000000),
      secondary: Color(0xFFDDDDDD),
      onSecondary: Color(0xFF000000),
      error: Color(0xFFCF6679),
      onError: Color(0xFF000000),
      background: Color(0xFF000000), // pure black background
      onBackground: Color(0xFFFFFFFF),
      surface: Color(0xFF121212), // dark surface
      onSurface: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFEEEEEE),
      onPrimaryContainer: Color(0xFF000000),
      secondaryContainer: Color(0xFFBFBFBF),
      onSecondaryContainer: Color(0xFF000000),
      surfaceVariant: Color(0xFF1E1E1E),
      outline: Color(0xFF444444),
      shadow: Color(0xFF000000),
      inverseSurface: Color(0xFFFFFFFF),
      onInverseSurface: Color(0xFF000000),
      inversePrimary: Color(0xFF111111),
    );
  }

  // ---------- ThemeData getters used by MaterialApp ----------
  ThemeData get lightTheme {
    if (_isMonochrome) {
      final cs = _monochromeLightScheme();
      return ThemeData(
        useMaterial3: true,
        colorScheme: cs,
        brightness: Brightness.light,
        scaffoldBackgroundColor: cs.background,
        appBarTheme: AppBarTheme(
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          elevation: 0,
          systemOverlayStyle: cs.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 0,
        ),
        splashFactory: NoSplash.splashFactory,
      );
    }

    // Normal colored theme using seed color
    final cs = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: Brightness.light,
      splashFactory: NoSplash.splashFactory,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
      ),
    );
  }

  ThemeData get darkTheme {
    if (_isMonochrome) {
      final cs = _monochromeDarkScheme();
      return ThemeData(
        useMaterial3: true,
        colorScheme: cs,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: cs.background,
        appBarTheme: AppBarTheme(
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          elevation: 0,
          systemOverlayStyle: cs.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 0,
        ),
        splashFactory: NoSplash.splashFactory,
      );
    }

    final cs = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: Brightness.dark,
      splashFactory: NoSplash.splashFactory,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
      ),
    );
  }
}
