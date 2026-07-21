import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flywheel_carousel/flywheel_carousel.dart';
import 'package:nix/ui/widgets/buttons/expressive_tone_button.dart';
import 'package:nix/ui/widgets/buttons/expressive_huge_button.dart';
import 'package:nix/ui/widgets/tiles/card_list_tile.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/ui/screens/controllers/onboarding_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final OnboardingPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingPageController()..init();
  }

  @override
  void dispose() {
    _controller.disposeController();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Page indicator
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: List.generate(4, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: index <= _controller.currentPage
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
                    controller: _controller.pageController,
                    onPageChanged: _controller.onPageChanged,
                    physics: const BouncingScrollPhysics(),
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
      },
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
          onPressed: _controller.nextPage,
          child: Icon(
            FlutterRemix.arrow_right_line,
            size: 30,
            color: colorScheme.onPrimary,
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
        ExpressiveToneButton(
          onPressed: _controller.nextPage,
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildPermissionsPage(ThemeData theme, ColorScheme colorScheme) {
    final allGranted =
        _controller.isAudioGranted && _controller.isNotificationGranted;

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Column(
                children: [
                  CardListTile(
                    isFirst: true,
                    leading: Icon(
                      FlutterRemix.headphone_line,
                      color: colorScheme.primary,
                    ),
                    title: 'Audio Access',
                    subtitle: 'Allow access to your audio files to play music',
                    trailing: _controller.isAudioGranted
                        ? Icon(
                            FlutterRemix.checkbox_circle_fill,
                            color: colorScheme.primary,
                          )
                        : const Icon(FlutterRemix.close_circle_line),
                    onTap: _controller.requestAudioPermission,
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
                    trailing: _controller.isNotificationGranted
                        ? Icon(
                            FlutterRemix.checkbox_circle_fill,
                            color: colorScheme.primary,
                          )
                        : const Icon(FlutterRemix.close_circle_line),
                    isLast: true,
                    onTap: _controller.requestNotificationPermission,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ExpressiveToneButton(
            onPressed: allGranted
                ? _controller.nextPage
                : _controller.isNotificationGranted
                ? _controller.requestAudioPermission
                : _controller.requestNotificationPermission,
            child: Text(allGranted ? 'Next' : 'Grant all permissions'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernamePage(ThemeData theme, ColorScheme colorScheme) {
    final isValid = _controller.nameController.text.trim().length >= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Setup your profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Flywheel Carousel for Avatar Selection (No Glow, Selected Scale Animation, No Looping)
          FlywheelCarousel<int>(
            height: 120,
            cardHeight: 90,
            viewportFraction: 0.28,
            loop: false,
            items: List.generate(UserProvider.avatarIcons.length, (i) => i),
            initialIndex: _controller.selectedAvatar,
            onIndexChanged: (index) => _controller.setAvatar(index),
            itemBuilder: (context, index, isSelected) {
              final color = UserProvider.avatarColors[index];
              return Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  scale: isSelected ? 1.15 : 0.85,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: color.withValues(alpha: 0.2),
                      child: Icon(
                        UserProvider.avatarIcons[index],
                        color: color,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          TextField(
            controller: _controller.nameController,
            decoration: InputDecoration(
              hintText: 'Your nickname',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _controller.onNameChanged,
          ),
          const SizedBox(height: 32),
          ExpressiveToneButton(
            onPressed: isValid
                ? () => _controller.finishOnboarding(context)
                : null,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
