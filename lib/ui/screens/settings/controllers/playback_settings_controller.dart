import 'package:flutter/material.dart';
import 'package:nix/providers/settings_provider.dart';

class PlaybackSettingsController extends ChangeNotifier {
  void toggleAutoPlay(SettingsProvider settings) {
    settings.setAutoPlay(!settings.autoPlay);
  }

  void toggleSkipSilence(SettingsProvider settings) {
    settings.setSkipSilence(!settings.skipSilence);
  }

  void toggleResetSpeedOnNewTrack(SettingsProvider settings) {
    settings.setResetSpeedOnNewTrack(!settings.resetSpeedOnNewTrack);
  }

  void toggleResumeFromPlayedDuration(SettingsProvider settings) {
    settings.setResumeFromPlayedDuration(!settings.resumeFromPlayedDuration);
  }

  void resetUpNextIndicatorTime(SettingsProvider settings) {
    settings.setUpNextIndicatorTime(20);
  }

  void toggleSaveLyricsOffline(SettingsProvider settings) {
    settings.setSaveLyricsOffline(!settings.saveLyricsOffline);
  }
}
