import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/ui/screens/navigation_screen.dart';

class OnboardingPageController extends ChangeNotifier {
  final PageController pageController = PageController();
  final TextEditingController nameController = TextEditingController(text: '');
  int currentPage = 0;
  bool isAudioGranted = false;
  bool isNotificationGranted = false;

  void init() {
    checkPermissions();
  }

  void onPageChanged(int index) {
    currentPage = index;
    notifyListeners();
  }

  void onNameChanged(String name) {
    notifyListeners();
  }

  Future<void> checkPermissions() async {
    final audio = await Permission.audio.status;
    final photos = await Permission.photos.status;
    final storage = await Permission.storage.status;
    isAudioGranted = audio.isGranted || photos.isGranted || storage.isGranted;

    final notif = await Permission.notification.status;
    isNotificationGranted = notif.isGranted;
    notifyListeners();
  }

  Future<void> requestAudioPermission() async {
    PermissionStatus status = await Permission.audio.request();
    if (status.isPermanentlyDenied || status.isDenied) {
      status = await Permission.storage.request();
    }
    if (status.isPermanentlyDenied || status.isDenied) {
      status = await Permission.photos.request();
    }
    isAudioGranted = status.isGranted;
    notifyListeners();
  }

  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    isNotificationGranted = status.isGranted;
    notifyListeners();
  }

  void nextPage() {
    pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> finishOnboarding(BuildContext context) async {
    final name = nameController.text.trim();
    final userProvider = context.read<UserProvider>();
    userProvider.setUserName(name.isEmpty ? '' : name);

    final box = Hive.box(HiveKeys.settingsBox);
    await box.put(HiveKeys.onboarding, true);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NavigationScreen()),
      );
    }
  }

  void disposeController() {
    pageController.dispose();
    nameController.dispose();
  }
}
