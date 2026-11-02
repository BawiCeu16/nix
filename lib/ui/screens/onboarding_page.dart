import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:m3e_buttons/m3e_buttons.dart' hide M3EHapticFeedback, M3EMotion;
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:m3e_haptics/m3e_haptics.dart';
import 'package:nix/ui/widgets/buttons/expressive_huge_button.dart';
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
        const SizedBox(height: 12),
        Text(
          'Welcome to nix',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'fast & minimal music player.',
          style: theme.textTheme.titleSmall?.copyWith(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FlutterRemix.shield_check_fill,
                  size: 80,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Privacy Matters',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'We respect your privacy and do/will not collect any personal information.',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: SizedBox(
              width: double.infinity,
              child: M3EButton(
                style: M3EButtonStyle.filled,
                shape: M3EButtonShape.round,
                size: M3EButtonSize.custom(
                  height: 48,
                  hPadding: 22,
                  iconSize: 20,
                  iconGap: 8,
                ),
                decoration: M3EButtonDecoration(
                  textStyle: theme.textTheme.labelLarge,
                  backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
                  foregroundColor: WidgetStatePropertyAll(
                    colorScheme.onPrimary,
                  ),
                  surfaceTintColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: _controller.nextPage,
                child: const Text('Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage(ThemeData theme, ColorScheme colorScheme) {
    final allGranted =
        _controller.isAudioGranted &&
        _controller.isNotificationGranted &&
        _controller.isBluetoothGranted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FlutterRemix.lock_unlock_fill,
                  size: 80,
                  color: colorScheme.secondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Permissions',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                M3ESegmentedColumn(
                  selectionMode: M3ESelectionMode.none,
                  color: colorScheme.surfaceContainer,
                  decoration: M3ESegmentedListDecoration(
                    color: colorScheme.surfaceContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 0,
                    ),
                    outerRadius: 24.0,
                    innerRadius: 4.0,
                    pressedRadius: 8.0,
                    pressedScale: 0.98,
                    hoveredRadius: 16.0,
                    gap: 2.0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    haptic: M3EHapticFeedback.medium,
                  ),
                  onTap: (index) {
                    if (index == 0) _controller.requestAudioPermission();
                    if (index == 1) _controller.requestNotificationPermission();
                    if (index == 2) _controller.requestBluetoothPermission();
                  },
                  children: [
                    M3EListItem(
                      supportingTextStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      headlineStyle: TextStyle(color: colorScheme.onSurface),
                      contentPadding: EdgeInsets.zero,
                      isThreeLine: false,
                      headline: const Text('Audio Access'),
                      supportingText: const Text(
                        'Allow access to your audio files to play music',
                      ),

                      leading: Icon(
                        FlutterRemix.headphone_line,
                        color: colorScheme.primary,
                      ),
                      trailing: _controller.isAudioGranted
                          ? Icon(
                              FlutterRemix.checkbox_circle_fill,
                              color: colorScheme.primary,
                            )
                          : null,
                    ),
                    M3EListItem(
                      supportingTextStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      headlineStyle: TextStyle(color: colorScheme.onSurface),

                      contentPadding: EdgeInsets.zero,
                      isThreeLine: false,
                      headline: const Text('Notifications'),
                      supportingText: const Text(
                        'Allow notifications to receive updates about your music',
                      ),
                      leading: Icon(
                        FlutterRemix.notification_3_line,
                        color: colorScheme.primary,
                      ),
                      trailing: _controller.isNotificationGranted
                          ? Icon(
                              FlutterRemix.checkbox_circle_fill,
                              color: colorScheme.primary,
                            )
                          : null,
                    ),
                    M3EListItem(
                      supportingTextStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      headlineStyle: TextStyle(color: colorScheme.onSurface),
                      contentPadding: EdgeInsets.zero,
                      isThreeLine: false,
                      headline: const Text('Bluetooth Access'),
                      supportingText: const Text(
                        'Allow access to Bluetooth devices for audio routing',
                      ),
                      leading: Icon(
                        FlutterRemix.bluetooth_line,
                        color: colorScheme.primary,
                      ),
                      trailing: _controller.isBluetoothGranted
                          ? Icon(
                              FlutterRemix.checkbox_circle_fill,
                              color: colorScheme.primary,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: SizedBox(
              width: double.infinity,
              child: M3EButton(
                style: M3EButtonStyle.filled,
                shape: M3EButtonShape.round,
                size: M3EButtonSize.custom(
                  height: 48,
                  hPadding: 22,
                  iconSize: 20,
                  iconGap: 8,
                ),
                decoration: M3EButtonDecoration(
                  textStyle: theme.textTheme.labelLarge,
                  backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
                  foregroundColor: WidgetStatePropertyAll(
                    colorScheme.onPrimary,
                  ),
                  surfaceTintColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: allGranted
                    ? _controller.nextPage
                    : !_controller.isAudioGranted
                    ? _controller.requestAudioPermission
                    : !_controller.isNotificationGranted
                    ? _controller.requestNotificationPermission
                    : _controller.requestBluetoothPermission,
                child: Text(allGranted ? 'Next' : 'Grant all permissions'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernamePage(ThemeData theme, ColorScheme colorScheme) {
    final isValid = _controller.nameController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What should we call you?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller.nameController,
            decoration: InputDecoration(
              hintText: 'Your name',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _controller.onNameChanged,
          ),
          const SizedBox(height: 32),
          M3EButton(
            style: M3EButtonStyle.filled,
            shape: M3EButtonShape.round,
            size: M3EButtonSize.custom(
              height: 48,
              hPadding: 22,
              iconSize: 20,
              iconGap: 8,
            ),
            decoration: M3EButtonDecoration(
              textStyle: theme.textTheme.labelLarge,
              backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
              foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
              surfaceTintColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            onPressed: isValid && _controller.nameController.text.length >= 4
                ? () => _controller.finishOnboarding(context)
                : null,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
