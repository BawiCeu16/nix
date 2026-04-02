import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../../providers/will_pop_provider.dart';
import '../../providers/current_music_provider.dart';
import '../miniplayer/now_playing.dart';
import 'main_pages/home_page/home_page.dart';
import 'main_pages/library_page/library_page.dart';
import 'main_pages/search_page/search_page.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController animation;
  double? bottom;

  // 1. ADD THIS: Keys to control each tab's independent Navigator
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Search
    GlobalKey<NavigatorState>(), // Library
  ];

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      upperBound: 2.1,
      lowerBound: -0.1,
      value: 0.0,
    );
    context.read<CurrentMusicProvider>().addListener(_onPlaybackChanged);
  }

  void _onPlaybackChanged() {
    final provider = context.read<CurrentMusicProvider>();
    if (provider.currentSong != null && animation.value < 0.0) {
      animation.value = 0.0;
    }
  }

  @override
  void dispose() {
    context.read<CurrentMusicProvider>().removeListener(_onPlaybackChanged);
    animation.dispose();
    super.dispose();
  }

  // 2. ADD THIS: A helper to build a nested Navigator for each tab
  Widget _buildTabNavigator(int index, Widget page) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => page,
          settings: settings,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bottom ??= MediaQuery.of(context).viewPadding.bottom;
    if (bottom == 0) bottom = null;

    return Consumer<WillPopProvider>(
      builder: (context, willPop, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, dynamic result) async {
            if (didPop) return;

            // A. Ask the provider if the player is open and needs to be closed
            final canPopApp = willPop.popper != null ? willPop.popper!() : true;
            if (!canPopApp) return;

            // B. If player is closed, check if the current tab has a page to go back to (like leaving AlbumsPage)
            final currentNavigator =
                _navigatorKeys[_selectedIndex].currentState;
            if (currentNavigator != null && currentNavigator.canPop()) {
              currentNavigator.pop();
              return; // Prevent app from closing
            }

            // C. If at the root of the tab and player is closed, allow app to close
            SystemNavigator.pop();
          },
          child: child!,
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SizedBox(
          height: double.infinity,
          child: Stack(
            children: [
              // Background Page Content (Scales down)
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return SizedBox(
                    height:
                        MediaQuery.of(context).size.height -
                        (1 - (animation.value).clamp(0.0, 1.0)) *
                            (80.0 + (bottom ?? 0)),
                    child: Transform.scale(
                      scale: (1 - animation.value.clamp(0.0, 1.0)) / 10 + 0.9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          (animation.value * 150.0).clamp(0.0, 42.0),
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    //pages
                    _buildTabNavigator(0, const HomePage()),
                    _buildTabNavigator(1, const SearchPage()),
                    _buildTabNavigator(2, const LibraryPage()),
                  ],
                ),
              ),

              // Bottom Navigation Bar
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        (animation.value * (20.0 + (bottom ?? 0))).clamp(
                          0,
                          120,
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: MediaQuery(
                    data: MediaQueryData(
                      padding: EdgeInsets.only(bottom: bottom ?? 0),
                    ),
                    child: NavigationBar(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (i) =>
                          setState(() => _selectedIndex = i),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(FlutterRemix.home_line),
                          selectedIcon: Icon(FlutterRemix.home_fill),
                          label: "Home",
                        ),
                        NavigationDestination(
                          icon: Icon(FlutterRemix.search_line),
                          selectedIcon: Icon(FlutterRemix.search_fill),
                          label: "Search",
                        ),
                        NavigationDestination(
                          icon: Icon(FlutterRemix.music_2_line),
                          selectedIcon: Icon(FlutterRemix.music_2_fill),
                          label: "Library",
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 1st Overlay: Opacity (Black + onSecondary Dimming)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: animation.value <= 0.01,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      if (animation.value > 0.01) {
                        return Container(
                          color: Theme.of(context).colorScheme.surface
                              .withValues(
                                alpha: (animation.value * 1.2).clamp(0, 1),
                              ),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ),
              ),

              // 2nd Overlay: Player Wallpaper
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: animation.value <= 0.01,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      if (animation.value > 0.01) {
                        return Opacity(
                          opacity: animation.value.clamp(0.0, 1.0),
                          child: Container(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ),
              ),

              // The Morphing Player Layer — hidden when no song selected
              Selector<CurrentMusicProvider, bool>(
                selector: (_, p) => p.currentSong != null,
                builder: (context, hasSong, child) {
                  if (!hasSong) return const SizedBox.shrink();
                  return child!;
                },
                child: NowPlaying(animation: animation),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
