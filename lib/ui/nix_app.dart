import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/ui/screens/navigation_screen.dart';
import 'package:nix/ui/screens/onboarding_page.dart';
import 'package:nix/ui/theme/nix_theme.dart';

/// Root application widget that configures Material 3 theming and entry routing.
class NixApp extends StatelessWidget {
  final bool hasCompletedOnboarding;

  const NixApp({super.key, required this.hasCompletedOnboarding});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Opt. #2: Use Selector2 to rebuild MaterialApp ONLY when theme-relevant
        // values change. This prevents skipSilence, playbackSpeed, etc. from
        // triggering a full app-level re-layout.
        return Selector2<SettingsProvider, CurrentMusicProvider, _ThemeConfig>(
          selector: (_, settings, music) => _ThemeConfig(
            accentColorMode: settings.accentColorMode,
            customAccentColor: settings.customAccentColor,
            useAmoledMode: settings.useAmoledMode,
            themeMode: settings.themeMode,
            dynamicSeedColor: music.dynamicSeedColor,
            lightDynamic: lightDynamic,
          ),
          builder: (context, config, child) {
            Color seedColor = Colors.blue;

            if (config.accentColorMode == AccentColorMode.device &&
                config.lightDynamic != null) {
              seedColor = config.lightDynamic!.primary;
            } else if (config.accentColorMode == AccentColorMode.dynamic) {
              seedColor = config.dynamicSeedColor ?? Colors.blue;
            } else if (config.accentColorMode == AccentColorMode.custom) {
              seedColor = config.customAccentColor;
            }

            final theme = NixTheme.buildLightTheme(seedColor);
            final darkTheme = NixTheme.buildDarkTheme(
              seedColor,
              amoled: config.useAmoledMode,
            );

            return MaterialApp(
              title: 'Nix',
              debugShowCheckedModeBanner: false,
              theme: theme,
              darkTheme: darkTheme,
              themeMode: config.themeMode,
              home: hasCompletedOnboarding
                  ? const NavigationScreen()
                  : const OnboardingPage(),
            );
          },
        );
      },
    );
  }
}

/// Immutable data class that holds theme-relevant settings.
/// Selector2 compares this object to decide if a rebuild is needed.
class _ThemeConfig {
  final AccentColorMode accentColorMode;
  final Color customAccentColor;
  final bool useAmoledMode;
  final ThemeMode themeMode;
  final Color? dynamicSeedColor;
  final ColorScheme? lightDynamic;

  const _ThemeConfig({
    required this.accentColorMode,
    required this.customAccentColor,
    required this.useAmoledMode,
    required this.themeMode,
    required this.dynamicSeedColor,
    required this.lightDynamic,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ThemeConfig &&
          accentColorMode == other.accentColorMode &&
          customAccentColor == other.customAccentColor &&
          useAmoledMode == other.useAmoledMode &&
          themeMode == other.themeMode &&
          dynamicSeedColor == other.dynamicSeedColor;

  @override
  int get hashCode => Object.hash(
    accentColorMode,
    customAccentColor,
    useAmoledMode,
    themeMode,
    dynamicSeedColor,
  );
}
