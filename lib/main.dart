import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/hive_keys.dart';
import 'providers/will_pop_provider.dart';
import 'providers/current_music_provider.dart';
import 'providers/music_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'providers/sleep_timer_provider.dart';
import 'ui/screens/navigation_screen.dart';
import 'ui/screens/onboarding_page.dart';
import 'ui/theme/nix_theme.dart';

CurrentMusicProvider? _audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(HiveKeys.settingsBox);

  _audioHandler = await AudioService.init(
    builder: () => CurrentMusicProvider(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.c.nix.channel.audio',
      androidNotificationChannelName: 'nix Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  /// Initialize audio handler before running app
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

class NixApp extends StatefulWidget {
  const NixApp({super.key});

  @override
  State<NixApp> createState() => _NixAppState();
}

class _NixAppState extends State<NixApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inject SettingsProvider into CurrentMusicProvider safely
    final settings = context.watch<SettingsProvider>();
    context.read<CurrentMusicProvider>().updateSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
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

            final theme = NixTheme.buildLightTheme(seedColor);
            final darkTheme = NixTheme.buildDarkTheme(
              seedColor,
              amoled: settings.useAmoledMode,
            );

            final settingsBox = Hive.box(HiveKeys.settingsBox);
            final bool hasCompletedOnboarding = settingsBox.get(
              HiveKeys.onboarding,
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
