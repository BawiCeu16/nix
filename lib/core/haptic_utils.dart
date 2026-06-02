import 'package:flutter/services.dart';
import 'package:nix/providers/settings_provider.dart';

/// Utility class for triggering haptic feedback with consistent intensity
/// based on user settings.
class HapticUtils {
  /// Triggers a vibration based on the user's preferred intensity.
  ///
  /// [force] allows overriding the intensity for specific actions,
  /// but typically it uses the global setting from [settings].
  static Future<void> trigger(
    SettingsProvider settings, {
    HapticForce? force,
  }) async {
    if (!settings.enableHaptics) return;

    final actualForce = force ?? settings.hapticForce;

    switch (actualForce) {
      case HapticForce.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticForce.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticForce.heavy:
        await HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Triggers a light selection click haptic.
  static Future<void> selection(SettingsProvider settings) async {
    if (!settings.enableHaptics) return;
    await HapticFeedback.selectionClick();
  }
}
