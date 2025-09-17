import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

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
  /// -> now applies a brightness/saturation boost so seed is more vivid.
  Future<void> updateColorFromAlbum(ImageProvider image) async {
    if (!_dynamicColorEnabled) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        image,
        maximumColorCount: 6,
      );

      // prefer vibrant -> dominant -> muted (but boost whichever we pick)
      final Color? picked =
          palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.mutedColor?.color;

      if (picked != null) {
        final boosted = _boostColorForSeed(picked);
        await setSeedColor(boosted);
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

  /// Extract a color for Now Playing background and make it brighter/vibrant.
  Future<void> updateNowPlayingColorFromImage(ImageProvider? image) async {
    if (!_dynamicNowPlayingEnabled || image == null) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        image,
        size: const Size(160, 160),
        maximumColorCount: 8,
      );

      // prefer most 'punchy' candidate
      final Color? candidate =
          palette.vibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.mutedColor?.color;

      if (candidate != null) {
        // boost more aggressively for now-playing so UI pops
        final boosted = _boostColorForNowPlaying(candidate);
        _nowPlayingBgColor = _ensureReadableBackground(boosted);
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint("NowPlaying Palette error: $e");
    }

    // fallback
    _nowPlayingBgColor = const Color(0xFF1F1F2A);
    notifyListeners();
  }

  void resetNowPlayingBgColor() {
    _nowPlayingBgColor = const Color(0xFF1F1F2A);
    notifyListeners();
  }

  /// Make the seed color slightly more vivid & brighter but keep it safe.
  Color _boostColorForSeed(Color color) {
    return _boostColor(color, saturationBoost: 0.16, lightnessBoost: 0.08);
  }

  /// Make now-playing color punchier (more boost)
  Color _boostColorForNowPlaying(Color color) {
    return _boostColor(color, saturationBoost: 0.22, lightnessBoost: 0.12);
  }

  /// Generic booster using HSL adjustments, with caps to avoid extremes.
  Color _boostColor(
    Color color, {
    double saturationBoost = 0.12,
    double lightnessBoost = 0.08,
  }) {
    final hsl = HSLColor.fromColor(color);
    double newS = (hsl.saturation + saturationBoost).clamp(0.0, 1.0);
    double newL = (hsl.lightness + lightnessBoost).clamp(0.03, 0.92);

    // if original was very dark, bump lightness a bit more so it's visible on dark backgrounds
    if (hsl.lightness < 0.12) {
      newL = math.min(0.28, newL + 0.06);
    }

    // if original is extremely low saturation (near grey), give it more saturation boost
    if (hsl.saturation < 0.12) {
      newS = math.min(1.0, newS + 0.08);
    }

    return HSLColor.fromAHSL(hsl.alpha, hsl.hue, newS, newL).toColor();
  }

  /// Ensure background color is readable but keep it on the brighter side.
  /// Avoid making it pitch-black or pure-white; nudge extremes toward comfortable contrast.
  Color _ensureReadableBackground(Color color) {
    final lum = color.computeLuminance();

    // too dark -> lift to readable but still moody
    if (lum < 0.08) {
      final h = HSLColor.fromColor(color);
      final lifted = h.withLightness(math.min(0.18, h.lightness + 0.18));
      return lifted.toColor();
    }

    // too bright -> slightly tone down to avoid white-blow
    if (lum > 0.94) {
      final h = HSLColor.fromColor(color);
      final toned = h.withLightness(math.max(0.88, h.lightness - 0.06));
      return toned.toColor();
    }

    // otherwise make a tiny friendly tweak so it's not flat
    final h = HSLColor.fromColor(color);
    final adjusted = h.withSaturation(math.min(1.0, h.saturation + 0.02));
    return adjusted.toColor();
  }

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
    // We'll use the (possibly boosted) _seedColor directly so it's more vivid.
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
