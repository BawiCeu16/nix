// lib/ui/pages/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/%20utils/translator.dart';
import 'package:nix/providers/app_info_provider.dart';
import 'package:nix/ui/pages/all_songs_screen.dart';
import 'package:nix/ui/pages/favorite_songs_screen.dart';
import 'package:nix/ui/pages/play_list_screen.dart';
import 'package:nix/ui/pages/most_listened_screen.dart';
import 'package:nix/ui/widgets/miniplayer_widget.dart';
import 'package:provider/provider.dart';
import '../../../providers/bottom_nav_provider.dart';

// Global ValueNotifier (kept here so you can drop this file in place)
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

/// Home container focused on performance:
/// - lazy screen instantiation
/// - keep-alive wrappers so heavy lists keep their state
/// - IndexedStack to preserve children and avoid rebuild/destruction
/// - minimal provider listening via context.select
class HomeWithNavigation extends StatefulWidget {
  const HomeWithNavigation({super.key});

  @override
  State<HomeWithNavigation> createState() => _HomeWithNavigationState();
}

class _HomeWithNavigationState extends State<HomeWithNavigation> {
  // cache screens so they are created only once
  final List<Widget?> _screensCache = List<Widget?>.filled(
    4,
    null,
    growable: false,
  );

  // PageStorageKeys preserve scroll positions across navigation
  final List<PageStorageKey> _pageKeys = const [
    PageStorageKey('page_all_songs'),
    PageStorageKey('page_playlists'),
    PageStorageKey('page_favorites'),
    PageStorageKey('page_most_listened'),
  ];

  @override
  void initState() {
    super.initState();
    // eagerly create first screen for immediate responsiveness
    _screensCache[0] = _keepAliveWrapper(const AllSongsScreen(), _pageKeys[0]);

    // run one-time post-frame work: show update dialog once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appInfo = context.read<AppInfoProvider>();
      if (appInfo.isNewVersion) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const FullScreenUpdateDialog(),
        );
        appInfo.markUpdateDialogShown();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _keepAliveWrapper(Widget child, Key key) {
    return _KeepAlivePage(key: key, child: child);
  }

  Widget _buildScreenForIndex(int index) {
    if (_screensCache[index] != null) return _screensCache[index]!;
    switch (index) {
      case 0:
        _screensCache[0] = _keepAliveWrapper(
          const AllSongsScreen(),
          _pageKeys[0],
        );
        break;
      case 1:
        _screensCache[1] = _keepAliveWrapper(
          const PlaylistScreen(),
          _pageKeys[1],
        );
        break;
      case 2:
        _screensCache[2] = _keepAliveWrapper(
          const FavoriteSongsScreen(),
          _pageKeys[2],
        );
        break;
      case 3:
        _screensCache[3] = _keepAliveWrapper(
          const MostListenedScreen(),
          _pageKeys[3],
        );
        break;
      default:
        _screensCache[index] = _keepAliveWrapper(
          const AllSongsScreen(),
          _pageKeys[0],
        );
    }
    return _screensCache[index]!;
  }

  @override
  Widget build(BuildContext context) {
    // listen only to the nav index — minimal rebuild
    final currentIndex = context.select<BottomNavProvider, int>(
      (p) => p.currentIndex,
    );

    // prefetch adjacent tab(s) to make switching instant
    // note: _buildScreenForIndex is cheap if cached
    final int nextIndex = (currentIndex + 1) % _screensCache.length;
    if (_screensCache[nextIndex] == null) _buildScreenForIndex(nextIndex);
    final int prevIndex =
        (currentIndex - 1 + _screensCache.length) % _screensCache.length;
    if (_screensCache[prevIndex] == null) _buildScreenForIndex(prevIndex);

    final bg = Theme.of(context).colorScheme.surfaceContainerLowest;
    final double bottomNavBarHeight = kBottomNavigationBarHeight + 16;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: IndexedStack(
                index: currentIndex,
                children: List<Widget>.generate(
                  _screensCache.length,
                  (i) => _buildScreenForIndex(i),
                ),
              ),
            ),
          ),

          // mini player overlay (kept outside IndexedStack)
          Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayerWidget(heightNotifier: miniPlayerHeightNotifier),
          ),
        ],
      ),

      // bottom nav: rebuilds only on mini-player height change (ValueListenable) and when index changes
      bottomNavigationBar: ValueListenableBuilder<double>(
        valueListenable: miniPlayerHeightNotifier,
        builder: (context, height, child) {
          final miniplayerMaxHeight =
              MediaQuery.of(context).size.height *
              MiniPlayerWidget.maxHeightFraction;
          final expansionPercentage =
              (height - MiniPlayerWidget.minHeight) /
              (miniplayerMaxHeight - MiniPlayerWidget.minHeight);
          final opacity = 1.0 - (expansionPercentage * 1.5).clamp(0.0, 1.0);

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
                child: _NavBar(currentIndex: currentIndex),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// minimal nav-bar separated to avoid parent rebuilds
class _NavBar extends StatelessWidget {
  final int currentIndex;
  const _NavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<BottomNavProvider>(context, listen: false);

    return NavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      selectedIndex: currentIndex,
      onDestinationSelected: navProvider.changeIndex,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      destinations: [
        NavigationDestination(
          icon: const Icon(FlutterRemix.music_line),
          selectedIcon: const Icon(FlutterRemix.music_fill),
          label: t(context, 'songs_nav'),
        ),
        NavigationDestination(
          icon: const Icon(FlutterRemix.play_list_line),
          selectedIcon: const Icon(FlutterRemix.play_list_fill),
          label: t(context, 'playlist_nav'),
        ),
        NavigationDestination(
          icon: const Icon(FlutterRemix.heart_line),
          selectedIcon: const Icon(FlutterRemix.heart_fill),
          label: t(context, 'favorites_nav'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.whatshot),
          selectedIcon: const Icon(Icons.whatshot),
          label: 'Top',
        ),
      ],
    );
  }
}

/// Keep-alive wrapper for heavy pages
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required Key key, required this.child})
    : super(key: key);

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin<_KeepAlivePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Full-screen update dialog (kept concise)
class FullScreenUpdateDialog extends StatelessWidget {
  const FullScreenUpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "What's New",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Here are the new features and changes in this version.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
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
                        const Text(
                          "Version 1.2.0 — Sep 3, 2025",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        const Text(
                          "Changes",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                        const Text(
                          "Notes & Known issues",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(right: 6.0),
                          child: Text(
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
      ),
    );
  }
}
