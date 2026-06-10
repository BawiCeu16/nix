import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/ui/screens/navigation_screen.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/ui/widgets/buttons/expressive_huge_button.dart';
import 'package:nix/ui/widgets/list_item/card_list_tile.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:nix/providers/user_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _currentPage = 0;

  bool _audioGranted = false;
  bool _notificationGranted = false;

  int _selectedAvatarIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!isMobile) {
      if (mounted) {
        setState(() {
          _audioGranted = true;
          _notificationGranted = true;
        });
      }
      return;
    }

    final audioStatus = await Permission.audio.status;
    final storageStatus = await Permission.storage.status;
    final notificationStatus = await Permission.notification.status;

    if (mounted) {
      setState(() {
        _audioGranted = audioStatus.isGranted || storageStatus.isGranted;
        _notificationGranted = notificationStatus.isGranted;
      });
    }
  }

  Future<void> _requestAudioPermission() async {
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!isMobile) {
      if (mounted) {
        setState(() {
          _audioGranted = true;
        });
      }
      return;
    }

    PermissionStatus status = await Permission.audio.status;
    if (!status.isGranted) {
      status = await Permission.audio.request();
    }

    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (mounted) {
      setState(() {
        _audioGranted = status.isGranted;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!isMobile) {
      if (mounted) {
        setState(() {
          _notificationGranted = true;
        });
      }
      return;
    }

    final status = await Permission.notification.request();
    if (mounted) {
      setState(() {
        _notificationGranted = status.isGranted;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index <= _currentPage
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const BouncingScrollPhysics(), // Force using buttons
                children: [
                  _buildWelcomePage(theme, colorScheme),
                  _buildPrivacyPage(theme, colorScheme),
                  _buildPermissionsPage(theme, colorScheme),
                  _buildUsernamePage(theme, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(FlutterRemix.music_2_fill, size: 80, color: colorScheme.primary),
        const SizedBox(height: 32),
        Text(
          'Welcome to Nix',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A fast, minimal music player',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 48),
        ExpressiveHugeButton(
          onPressed: _nextPage,
          child: Icon(
            FlutterRemix.arrow_right_line,
            size: 30,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyPage(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          FlutterRemix.shield_check_fill,
          size: 80,
          color: colorScheme.tertiary,
        ),
        const SizedBox(height: 32),
        Text(
          'Your Privacy Matters',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We respect your privacy and will not collect any personal information',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        ExpressiveToneButton(onPressed: _nextPage, child: const Text('Next')),
      ],
    );
  }

  Widget _buildPermissionsPage(ThemeData theme, ColorScheme colorScheme) {
    final allGranted = _audioGranted && _notificationGranted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FlutterRemix.lock_unlock_fill,
            size: 80,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: 32),
          Text(
            'Permissions',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Column(
                spacing: 0,
                children: [
                  CardListTile(
                    isFirst: true,
                    leading: Icon(
                      FlutterRemix.headphone_line,
                      color: colorScheme.primary,
                    ),
                    title: 'Audio Access',
                    subtitle: 'Allow access to your audio files to play music',
                    trailing: _audioGranted
                        ? Icon(
                            FlutterRemix.checkbox_circle_fill,
                            color: colorScheme.primary,
                          )
                        : const Icon(FlutterRemix.close_circle_line),

                    onTap: _requestAudioPermission,
                  ),
                  const SizedBox(height: 2.5),
                  CardListTile(
                    isFirst: false,

                    leading: Icon(
                      FlutterRemix.notification_3_line,
                      color: colorScheme.primary,
                    ),
                    title: 'Notifications',
                    subtitle:
                        'Allow notifications to receive updates about your music',
                    trailing: _notificationGranted
                        ? Icon(
                            FlutterRemix.checkbox_circle_fill,
                            color: colorScheme.primary,
                          )
                        : const Icon(FlutterRemix.close_circle_line),
                    isLast: true,
                    onTap: _requestNotificationPermission,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          ExpressiveToneButton(
            onPressed: allGranted
                ? _nextPage
                : _notificationGranted
                ? _requestAudioPermission
                : _requestNotificationPermission,
            child: Text(allGranted ? 'Next' : 'Grant all permissions'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernamePage(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Setup your profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: UserProvider.avatarIcons.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedAvatarIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatarIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: UserProvider.avatarColors[index]
                          .withValues(alpha: 0.2),
                      child: Icon(
                        UserProvider.avatarIcons[index],
                        color: UserProvider.avatarColors[index],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Your nickname',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 40),
          ExpressiveToneButton(
            onPressed:
                _nameController.text.trim().isNotEmpty &&
                    _nameController.text.trim().length >= 3
                ? () async {
                    final settingsBox = Hive.box('settings');
                    final userProvider = context.read<UserProvider>();

                    await settingsBox.put('hasCompletedOnboarding', true);
                    userProvider.setUserName(_nameController.text.trim());
                    userProvider.setAvatarIndex(_selectedAvatarIndex);

                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const NavigationScreen(),
                      ),
                    );
                  }
                : null,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
