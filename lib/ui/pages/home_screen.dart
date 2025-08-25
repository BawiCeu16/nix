import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/%20utils/translator.dart';
import 'package:nix/ui/pages/all_songs_screen.dart';
import 'package:nix/ui/pages/favorite_songs_screen.dart';
import 'package:nix/ui/pages/play_list_screen.dart';
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
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      // backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          // Expanded(child: screens[navProvider.currentIndex]),
          // MiniPlayerWidget(heightNotifier: miniPlayerHeightNotifier),
          // Pass the ValueNotifier to the MiniPlayerWidget

          // Main screen
          Positioned.fill(
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),

                child: screens[navProvider.currentIndex],
              ),
            ),
          ), // Miniplayer
          Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayerWidget(heightNotifier: miniPlayerHeightNotifier),
          ),
        ],
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
            height:
                bottomNavBarHeight - bottomNavBarHeight * expansionPercentage,
            child: Transform.translate(
              offset: Offset(
                0.0,
                bottomNavBarHeight * expansionPercentage * 0.5,
              ),
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
            //Songs
            NavigationDestination(
              icon: Icon(FlutterRemix.music_line),
              selectedIcon: Icon(FlutterRemix.music_fill),
              label: t(context, 'songs_nav'),
            ),
            //PlayLists
            NavigationDestination(
              icon: Icon(FlutterRemix.play_list_line),
              selectedIcon: Icon(FlutterRemix.play_list_fill),
              label: t(context, 'playlist_nav'),
            ),
            //Favorites
            NavigationDestination(
              icon: Icon(FlutterRemix.heart_line),
              selectedIcon: Icon(FlutterRemix.heart_fill),
              label: t(context, 'favorites_nav'),
            ),
          ],
        ),
      ),
    );
  }
}
