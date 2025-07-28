import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/pages/all_songs_screen.dart';
import 'package:nix/ui/pages/favorite_songs_screen.dart';
import 'package:nix/ui/pages/settings_page.dart';
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
    final navProvider = Provider.of<BottomNavProvider>(context);
    final List<Widget> screens = const [
      AllSongsScreen(),
      FavoriteSongsScreen(),
      SettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Expanded(child: screens[navProvider.currentIndex]),
            // MiniPlayerWidget(heightNotifier: miniPlayerHeightNotifier),
            // Pass the ValueNotifier to the MiniPlayerWidget

            // Main screen
            Positioned.fill(
              child: screens[navProvider.currentIndex],
            ), // Miniplayer
            Align(
              alignment: Alignment.bottomCenter,
              child: MiniPlayerWidget(heightNotifier: miniPlayerHeightNotifier),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<double>(
        valueListenable: miniPlayerHeightNotifier,
        builder: (context, height, child) {
          // Calculate the percentage of miniplayer expansion
          final miniplayerMaxHeight =
              MediaQuery.of(context).size.height *
              MiniPlayerWidget.maxHeightFraction;
          final expansionPercentage =
              (height - MiniPlayerWidget.minHeight) /
              (miniplayerMaxHeight - MiniPlayerWidget.minHeight);

          // Determine the opacity and vertical offset for the NavigationBar
          // It starts to hide when the miniplayer expands
          final opacity = 1.0 - (expansionPercentage * 1.5).clamp(0.0, 1.0);

          //     // Make it disappear faster
          // final verticalOffset =
          //     kBottomNavigationBarHeight * expansionPercentage;

          return SizedBox(
            height: 65 - 65 * expansionPercentage,
            child: Transform.translate(
              offset: Offset(0.0, 65 * expansionPercentage * 0.5),
              child: Opacity(
                opacity: opacity,
                child: OverflowBox(maxHeight: 65, child: child),
              ),
            ),
          );
        },
        child: NavigationBar(
          selectedIndex: navProvider.currentIndex,
          onDestinationSelected: navProvider.changeIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(FlutterRemix.music_line),
              selectedIcon: Icon(FlutterRemix.music_fill),
              label: "Songs",
            ),
            NavigationDestination(
              icon: Icon(FlutterRemix.heart_line),
              selectedIcon: Icon(FlutterRemix.heart_fill),
              label: "Favorites",
            ),
            NavigationDestination(
              icon: Icon(FlutterRemix.settings_line),
              selectedIcon: Icon(FlutterRemix.settings_fill),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }
}
