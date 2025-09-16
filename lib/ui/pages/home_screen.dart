// lib/ui/pages/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/%20utils/translator.dart';
import 'package:nix/providers/app_info_provider.dart';
import 'package:nix/ui/pages/all_songs_screen.dart';
import 'package:nix/ui/pages/favorite_songs_screen.dart';
import 'package:nix/ui/pages/play_list_screen.dart';
import 'package:nix/ui/pages/most_listened_screen.dart'; // new
import 'package:nix/ui/widgets/miniplayer_widget.dart';
import 'package:provider/provider.dart';
import '../../../providers/bottom_nav_provider.dart';

// Create a ValueNotifier for the miniplayer's height
final ValueNotifier<double> miniPlayerHeightNotifier = ValueNotifier<double>(
  MiniPlayerWidget.minHeight,
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: HomeWithNavigation());
  }
}

class HomeWithNavigation extends StatelessWidget {
  const HomeWithNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    double bottomNavBarHeight = kBottomNavigationBarHeight + 16;
    final navProvider = Provider.of<BottomNavProvider>(context);

    final List<Widget> screens = const [
      //Screens from Main
      AllSongsScreen(),
      PlaylistScreen(),
      FavoriteSongsScreen(),
      MostListenedScreen(), // newly added tab
    ];
    final appInfo = Provider.of<AppInfoProvider>(context);

    // Trigger dialog only once per session, after build
    if (appInfo.isNewVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const FullScreenUpdateDialog(),
        );

        // Mark dialog as shown so it won't trigger again until next update
        appInfo.markUpdateDialogShown();
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: screens[navProvider.currentIndex],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayerWidget(heightNotifier: miniPlayerHeightNotifier),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<double>(
        valueListenable: miniPlayerHeightNotifier,
        builder: (context, height, child) {
          final miniplayerMaxHeight =
              MediaQuery.of(context).size.height * MiniPlayerWidget.maxHeightFraction;
          final expansionPercentage =
              (height - MiniPlayerWidget.minHeight) /
              (miniplayerMaxHeight - MiniPlayerWidget.minHeight);

          final opacity = 1.0 - (expansionPercentage * 1.5).clamp(0.0, 1.0);

          return SizedBox(
            height: bottomNavBarHeight - bottomNavBarHeight * expansionPercentage,
            child: Transform.translate(
              offset: Offset(0.0, bottomNavBarHeight * expansionPercentage * 0.5),
              child: Opacity(
                opacity: opacity,
                child: OverflowBox(maxHeight: bottomNavBarHeight, child: child),
              ),
            ),
          );
        },
        child: NavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          selectedIndex: navProvider.currentIndex,
          onDestinationSelected: navProvider.changeIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: [
            NavigationDestination(
              icon: Icon(FlutterRemix.music_line),
              selectedIcon: Icon(FlutterRemix.music_fill),
              label: t(context, 'songs_nav'),
            ),
            NavigationDestination(
              icon: Icon(FlutterRemix.play_list_line),
              selectedIcon: Icon(FlutterRemix.play_list_fill),
              label: t(context, 'playlist_nav'),
            ),
            NavigationDestination(
              icon: Icon(FlutterRemix.heart_line),
              selectedIcon: Icon(FlutterRemix.heart_fill),
              label: t(context, 'favorites_nav'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.whatshot),
              selectedIcon: const Icon(Icons.whatshot),
              label: 'Top',
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenUpdateDialog extends StatelessWidget {
  const FullScreenUpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox.expand(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "What's New",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Here are the new features and changes in this version.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Version 1.2.0 — Sep 3, 2025",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            ListTile(
                              leading: Icon(FlutterRemix.palette_line),
                              title: const Text("Dynamic theme from album image"),
                              subtitle: const Text(
                                "App extracts prominent colors from the current track's album art and applies them to the player for a richer visual experience.",
                              ),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                            ),
                            ListTile(
                              leading: const Icon(Icons.lyrics_outlined),
                              title: const Text("support Lyrics"),
                              subtitle: const Text(
                                "Added Lyrics feature this time but not fully implemented.",
                              ),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(height: 12),
                            const Text("Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ListTile(
                              leading: Icon(FlutterRemix.check_fill),
                              title: const Text("Changed Theme issue"),
                              subtitle: const Text(
                                "change some theme issue from light mode in song list.",
                              ),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(height: 12),
                            const Text("Notes & Known issues", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: const Text(
                                "• If you see the permission screen again on some devices, grant storage/media permissions and restart the app.\n"
                                "• We're still polishing a rare edge-case where very large album images may take slightly longer to compute theme colors.\n"
                                "• Disclaimer: “Lyrics are provided by LRCLIB.net and may be copyrighted.”",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 40,
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Okay"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
