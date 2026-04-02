import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'providers/will_pop_provider.dart';
import 'providers/current_music_provider.dart';
import 'providers/music_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'providers/sleep_timer_provider.dart';
import 'ui/screens/navigation_screen.dart';
import 'ui/screens/onboarding_page.dart';

import 'package:dynamic_color/dynamic_color.dart';

CurrentMusicProvider? _audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');

  _audioHandler = await AudioService.init(
    builder: () => CurrentMusicProvider(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.c.nix.channel.audio',
      androidNotificationChannelName: 'nix Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  // Initialize audio handler
  await _audioHandler!.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentMusicProvider>.value(
          value: _audioHandler!,
        ),
        ChangeNotifierProvider(
          create: (_) => MusicProvider()..init(currentMusic: _audioHandler),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SleepTimerProvider()),
        Provider(create: (_) => WillPopProvider()),
      ],
      child: const NixApp(),
    ),
  );
}

class NixApp extends StatelessWidget {
  const NixApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject SettingsProvider into CurrentMusicProvider
    final settings = context.watch<SettingsProvider>();
    context.read<CurrentMusicProvider>().updateSettings(settings);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Consumer2<SettingsProvider, CurrentMusicProvider>(
          builder: (context, settings, music, child) {
            Color seedColor = Colors.blue;

            // Determine seed color based on mode
            if (settings.accentColorMode == AccentColorMode.device &&
                lightDynamic != null) {
              seedColor = lightDynamic.primary;
            } else if (settings.accentColorMode == AccentColorMode.dynamic) {
              seedColor = music.dynamicSeedColor ?? Colors.blue;
            } else if (settings.accentColorMode == AccentColorMode.custom) {
              seedColor = settings.customAccentColor;
            }

            final theme = ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ),
              splashFactory: NoSplash.splashFactory,
              useMaterial3: true,
            );

            final darkTheme = ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ),
              splashFactory: NoSplash.splashFactory,
              useMaterial3: true,
            );

            final settingsBox = Hive.box('settings');
            final bool hasCompletedOnboarding = settingsBox.get(
              'hasCompletedOnboarding',
              defaultValue: false,
            );

            return MaterialApp(
              title: 'Nix',
              debugShowCheckedModeBanner: false,
              theme: theme,
              darkTheme: darkTheme,
              themeMode: settings.themeMode,
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
