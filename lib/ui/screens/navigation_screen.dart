import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/will_pop_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/miniplayer/now_playing.dart';
import 'package:nix/ui/screens/main/home_page.dart';
import 'package:nix/ui/screens/main/library_page.dart';
import 'package:nix/ui/screens/main/search_page.dart';
import 'package:nix/ui/screens/controllers/navigation_controller.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with SingleTickerProviderStateMixin {
  late final NavigationScreenController _controller;

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
    _controller = NavigationScreenController()..init(this, context);
  }

  @override
  void dispose() {
    _controller.disposeController(context);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.updateBottomInset(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final bottom = _controller.bottom;

        return Consumer<WillPopProvider>(
          builder: (context, willPop, child) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (bool didPop, dynamic result) =>
                  _controller.handlePopInvoked(
                didPop: didPop,
                context: context,
                willPop: willPop,
              ),
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
                    animation: _controller.animation,
                    builder: (context, child) {
                      return SizedBox(
                        height:
                            MediaQuery.of(context).size.height -
                            (1 - (_controller.animation.value).clamp(0.0, 1.0)) *
                                (80.0 + (bottom ?? 0)),
                        child: Transform.scale(
                          scale:
                              (1 - _controller.animation.value.clamp(0.0, 1.0)) /
                                  10 +
                              0.9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              (_controller.animation.value * 150.0).clamp(0.0, 42.0),
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: IndexedStack(
                      index: _controller.selectedIndex,
                      children: [
                        _controller.buildTabNavigator(
                          context: context,
                          index: 0,
                          page: const HomePage(),
                        ),
                        _controller.buildTabNavigator(
                          context: context,
                          index: 1,
                          page: const SearchPage(),
                        ),
                        _controller.buildTabNavigator(
                          context: context,
                          index: 2,
                          page: const LibraryPage(),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Navigation Bar
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedBuilder(
                      animation: _controller.animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            (_controller.animation.value * (20.0 + (bottom ?? 0)))
                                .clamp(0, 120),
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
                          selectedIndex: _controller.selectedIndex,
                          onDestinationSelected: _controller.setSelectedIndex,
                          destinations: _navDestinations,
                        ),
                      ),
                    ),
                  ),

                  // Player Overlay: Opacity (Black + onSecondary Dimming) & Wallpaper
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _controller.animation.value <= 0.01,
                      child: AnimatedBuilder(
                        animation: _controller.animation,
                        builder: (context, child) {
                          if (_controller.animation.value <= 0.01) {
                            return const SizedBox();
                          }

                          final opacityValue =
                              _controller.animation.value.clamp(0.0, 1.0);
                          final dimValue =
                              (_controller.animation.value * 1.2).clamp(0.0, 1.0);
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
                      animation: _controller.animation,
                      bottomInset: bottom ?? 0.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
