import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/providers/will_pop_provider.dart';

class NavigationScreenController extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  late final AnimationController animation;
  double? bottom;
  bool _isPlayerOpen = false;
  bool get isPlayerOpen => _isPlayerOpen;

  final List<GlobalKey<NavigatorState>> navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late final VoidCallback _playbackListener;

  void init(TickerProvider vsync, BuildContext context) {
    animation = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 500),
      upperBound: 2.1,
      lowerBound: -0.1,
      value: 0.0,
    );

    animation.addListener(() {
      final bool isOpen = animation.value > 0.01;
      if (isOpen != _isPlayerOpen) {
        _isPlayerOpen = isOpen;
        notifyListeners();
      }
    });

    final musicProvider = context.read<CurrentMusicProvider>();
    _playbackListener = () => _onPlaybackChanged(musicProvider);
    musicProvider.addListener(_playbackListener);
  }

  void _onPlaybackChanged(CurrentMusicProvider provider) {
    if (provider.currentTrack != null && animation.value < 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (animation.value < 0.0) {
          animation.value = 0.0;
        }
      });
    }
  }

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void updateBottomInset(BuildContext context) {
    double? newBottom = MediaQuery.of(context).viewPadding.bottom;
    if (newBottom == 0) newBottom = null;
    if (bottom != newBottom) {
      bottom = newBottom;
      notifyListeners();
    }
  }

  Future<void> handlePopInvoked({
    required bool didPop,
    required BuildContext context,
    required WillPopProvider willPop,
  }) async {
    debugPrint(
      "NavigationScreenController: handlePopInvoked. didPop: $didPop, handler isNull: ${willPop.handler == null}",
    );
    if (didPop) return;

    // 1. Handle dialogs or pages pushed on top of the root navigator first
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      debugPrint("NavigationScreenController: popping top route on root navigator");
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    // 2. Ask the provider if the player is open and needs to be closed
    final canPopApp = willPop.handler != null ? willPop.handler!() : true;
    debugPrint("NavigationScreenController: canPopApp: $canPopApp");
    if (!canPopApp) return;

    // 3. If player is closed, check if the current tab has a page to go back to
    final currentNavigator = navigatorKeys[_selectedIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return;
    }

    // 4. If at the root of the tab and player is closed, allow app to close
    SystemNavigator.pop();
  }

  Widget buildTabNavigator({
    required BuildContext context,
    required int index,
    required Widget page,
  }) {
    final route = ModalRoute.of(context);
    final isCurrent = route == null || route.isCurrent;
    final canPopTab = isCurrent && !_isPlayerOpen;

    return PopScope(
      canPop: canPopTab,
      child: Navigator(
        key: navigatorKeys[index],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => page,
            settings: settings,
          );
        },
      ),
    );
  }

  void disposeController(BuildContext context) {
    context.read<CurrentMusicProvider>().removeListener(_playbackListener);
    animation.dispose();
  }
}
