import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.blue;
  bool _isMonochrome = false;
  bool _dynamicColorEnabled = false; // existing dynamic theme (keep)

  // ---- NEW for Now Playing ----
  bool _dynamicNowPlayingEnabled = false; // toggle ON/OFF by user
  Color _nowPlayingBgColor = const Color(0xFF1F1F2A); // default not black

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get isMonochrome => _isMonochrome;
  bool get dynamicColorEnabled => _dynamicColorEnabled;

  // ---- NEW getters ----
  bool get dynamicNowPlayingEnabled => _dynamicNowPlayingEnabled;
  Color get nowPlayingBgColor => _nowPlayingBgColor;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
    final colorValue = prefs.getInt('seedColor');
    if (colorValue != null) _seedColor = Color(colorValue);
    _isMonochrome = prefs.getBool('isMonochrome') ?? false;
    _dynamicColorEnabled = prefs.getBool('dynamicColor') ?? false; // load

    // ---- NEW load flag ----
    _dynamicNowPlayingEnabled =
        prefs.getBool('dynamicNowPlayingEnabled') ?? false;

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

  Future<void> setDynamicColorEnabled(bool enabled) async {
    _dynamicColorEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dynamicColor', enabled);
  }

  /// Extracts color from album image & updates theme
  Future<void> updateColorFromAlbum(ImageProvider image) async {
    if (!_dynamicColorEnabled) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(image);
      final dominant = palette.dominantColor?.color;
      if (dominant != null) {
        await setSeedColor(dominant);
      }
    } catch (e) {
      debugPrint("Palette error: $e");
    }
  }

  // ---------- NEW METHODS for Now Playing background ----------
  Future<void> setDynamicNowPlayingEnabled(bool enabled) async {
    _dynamicNowPlayingEnabled = enabled;
    if (!enabled) {
      _nowPlayingBgColor = const Color(0xFF1F1F2A); // reset default
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dynamicNowPlayingEnabled', enabled);
  }

  Future<void> updateNowPlayingColorFromImage(ImageProvider? image) async {
    if (!_dynamicNowPlayingEnabled || image == null) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        image,
        size: const Size(120, 120),
        maximumColorCount: 6,
      );
      final Color? chosen =
          palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.mutedColor?.color;

      if (chosen != null) {
        _nowPlayingBgColor = _ensureReadableBackground(chosen);
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint("NowPlaying Palette error: $e");
    }
    _nowPlayingBgColor = const Color(0xFF1F1F2A); // fallback
    notifyListeners();
  }

  void resetNowPlayingBgColor() {
    _nowPlayingBgColor = const Color(0xFF1F1F2A);
    notifyListeners();
  }

  Color _ensureReadableBackground(Color color) {
    final lum = color.computeLuminance();
    if (lum > 0.85) {
      return HSLColor.fromColor(color).withLightness(0.20).toColor();
    }
    if (lum < 0.05) {
      return HSLColor.fromColor(color).withLightness(0.10).toColor();
    }
    return color;
  }
  // ---------- END NEW ----------

  // ---------- MONOCHROME PALETTES ----------
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
      surfaceContainerLow: Color(0xFFE8E8E8), // light surface
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
      surface: Color(0xFF000000), // dark surface
      surfaceContainerLow: Color(0xFF0A0A0A), // dark surface
      onSurface: Color(0xFFBFBFBF),
      primaryContainer: Color(0xFFEEEEEE),
      onPrimaryContainer: Color(0xFF000000),
      secondaryContainer: Color(0xFFBFBFBF),
      onSecondaryContainer: Color(0xFF000000),
      surfaceVariant: Color(0xFF1E1E1E),
      outline: Color(0xFF444444),
      shadow: Color(0xFF000000),
      inverseSurface: Color(0xFFFFFFFF),
      onInverseSurface: Color(0xFF000000),
      inversePrimary: Color(0xFF000000),
    );
  }

  // ---------- ThemeData ----------
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
