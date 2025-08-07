import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:nix/providers/app_info_provider.dart';
import 'package:nix/providers/bottom_nav_provider.dart';
import 'package:nix/providers/language_provider.dart';
import 'package:nix/providers/theme_provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/ui/pages/home_screen.dart';
import 'package:nix/ui/pages/name_input_screen.dart';
import 'package:nix/ui/pages/permission_screen.dart';
import 'package:provider/provider.dart';
import 'providers/music_provider.dart';
import 'providers/permission_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.c.nix.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    preloadArtwork: true,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final musicProvider = MusicProvider();
  final themeProvider = ThemeProvider();
  final appInfoProvider = AppInfoProvider();
  final languageProvider = LanguageProvider();

  await musicProvider.loadFavorites();
  await themeProvider.loadTheme();
  await appInfoProvider.loadAppInfo();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => musicProvider),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => appInfoProvider),
        ChangeNotifierProvider(create: (_) => languageProvider),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
      ],
      child: const NixApp(),
    ),
  );
}

class NixApp extends StatelessWidget {
  const NixApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Consumer<LanguageProvider>(
      builder: (context, value, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nix',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.seedColor,
            ),
            splashFactory: NoSplash.splashFactory,
            brightness: Brightness.light,
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.seedColor,
              brightness: Brightness.dark,
            ),
            splashFactory: NoSplash.splashFactory,
            brightness: Brightness.dark,
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              elevation: 0,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: FutureBuilder<bool>(
            future: PermissionProvider.isPermissionsCompleted(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final permissionCompleted = snapshot.data!;
              return Consumer2<UserProvider, PermissionProvider>(
                builder: (context, userProvider, permissionProvider, _) {
                  if (userProvider.isLoading || permissionProvider.isLoading) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!permissionCompleted || !permissionProvider.allGranted) {
                    return const PermissionScreen();
                  }

                  if (userProvider.username == null) {
                    return const NameInputScreen();
                  }

                  return const HomeScreen();
                },
              );
            },
          ),

          routes: {
            '/name': (_) => const NameInputScreen(),
            '/home': (_) => const HomeScreen(),
          },
        );
      },
    );
  }
}
