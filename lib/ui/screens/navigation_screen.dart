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
  bool _isPlayerOpen = false;
  Animation<double>? _secondaryAnimation;

  // Keys to control each tab's independent Navigator
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  static const List<NavigationDestination> _navDestinations = [
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
    animation.addListener(() {
      final bool isOpen = animation.value > 0.01;
      if (isOpen != _isPlayerOpen) {
        setState(() {
          _isPlayerOpen = isOpen;
        });
      }
    });
    context.read<CurrentMusicProvider>().addListener(_onPlaybackChanged);
  }

  void _onPlaybackChanged() {
    final provider = context.read<CurrentMusicProvider>();
    if (provider.currentTrack != null && animation.value < 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && animation.value < 0.0) {
          animation.value = 0.0;
        }
      });
    }
  }

  void _routeListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final secAnim = route?.secondaryAnimation;
    if (secAnim != _secondaryAnimation) {
      _secondaryAnimation?.removeListener(_routeListener);
      _secondaryAnimation = secAnim;
      _secondaryAnimation?.addListener(_routeListener);
    }
  }

  @override
  void dispose() {
    _secondaryAnimation?.removeListener(_routeListener);
    context.read<CurrentMusicProvider>().removeListener(_onPlaybackChanged);
    animation.dispose();
    super.dispose();
  }

  // Helper to build a nested Navigator for each tab
  Widget _buildTabNavigator(int index, Widget page) {
    final route = ModalRoute.of(context);
    final isCurrent = route == null || route.isCurrent;
    final canPopTab = isCurrent && !_isPlayerOpen;

    return PopScope(
      canPop: canPopTab,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => page,
            settings: settings,
          );
        },
      ),
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
            debugPrint("NavigationScreen: onPopInvokedWithResult. didPop: $didPop, handler isNull: ${willPop.handler == null}");
            if (didPop) return;

            // 1. Handle dialogs or pages pushed on top of the root navigator first
            final route = ModalRoute.of(context);
            if (route != null && !route.isCurrent) {
              debugPrint("NavigationScreen: popping top route on root navigator");
              Navigator.of(context, rootNavigator: true).pop();
              return;
            }

            // 2. Ask the provider if the player is open and needs to be closed
            final canPopApp = willPop.handler != null
                ? willPop.handler!()
                : true;
            debugPrint("NavigationScreen: canPopApp: $canPopApp");
            if (!canPopApp) return;

            // 3. If player is closed, check if the current tab has a page to go back to (like leaving AlbumsPage)
            final currentNavigator =
                _navigatorKeys[_selectedIndex].currentState;
            if (currentNavigator != null && currentNavigator.canPop()) {
              currentNavigator.pop();
              return; // Prevent app from closing
            }

            // 4. If at the root of the tab and player is closed, allow app to close
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
                      destinations: _navDestinations,
                    ),
                  ),
                ),
              ),

              // Player Overlay: Opacity (Black + onSecondary Dimming) & Wallpaper
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: animation.value <= 0.01,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      if (animation.value <= 0.01) return const SizedBox();

                      final opacityValue = animation.value.clamp(0.0, 1.0);
                      final dimValue = (animation.value * 1.2).clamp(0.0, 1.0);
                      final surfaceColor = Theme.of(
                        context,
                      ).colorScheme.surface;

                      return Stack(
                        children: [
                          Container(
                            color: surfaceColor.withValues(alpha: dimValue),
                          ),
                          Opacity(
                            opacity: opacityValue,
                            child: Container(color: surfaceColor),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // The Morphing Player Layer — hidden when no track selected
              Selector<CurrentMusicProvider, bool>(
                selector: (_, p) => p.currentTrack != null,
                builder: (context, hasTrack, child) {
                  if (!hasTrack) return const SizedBox.shrink();
                  return child!;
                },
                child: NowPlaying(
                  animation: animation,
                  bottomInset: bottom ?? 0.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
