import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/artwork_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/lyrics_provider.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/settings_provider.dart';
import 'package:nix/providers/sleep_timer_provider.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/providers/will_pop_provider.dart';

/// Configures and injects all application-level providers and proxy dependencies.
class AppProviders extends StatelessWidget {
  final CurrentMusicProvider audioHandler;
  final Widget child;

  const AppProviders({
    super.key,
    required this.audioHandler,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, CurrentMusicProvider>(
          create: (_) => audioHandler,
          update: (_, settings, player) => player!..updateSettings(settings),
        ),
        ChangeNotifierProxyProvider2<
          SettingsProvider,
          CurrentMusicProvider,
          LyricsProvider
        >(
          create: (_) => LyricsProvider(),
          update: (_, settings, music, lyrics) =>
              lyrics!..update(settings, music),
        ),
        ChangeNotifierProvider(
          create: (_) => MusicProvider()..init(currentMusic: audioHandler),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SleepTimerProvider()),
        ChangeNotifierProvider(create: (_) => ArtworkProvider()),
        ChangeNotifierProvider(create: (_) => WillPopProvider()),
      ],
      child: child,
    );
  }
}
