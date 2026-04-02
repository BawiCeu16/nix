import 'dart:async';
import 'package:flutter/material.dart';
import 'current_music_provider.dart';

class SleepTimerProvider extends ChangeNotifier {
  Timer? _timer;
  Duration? _remainingTime;
  
  bool get isActive => _timer != null;
  Duration? get remainingTime => _remainingTime;

  /// Starts a sleep timer for the given [duration].
  void setTimer(Duration duration, CurrentMusicProvider music) {
    cancel();
    _remainingTime = duration;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == null) {
        cancel();
        return;
      }

      if (_remainingTime!.inSeconds <= 0) {
        _onFinished(music);
      } else {
        _remainingTime = _remainingTime! - const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  /// Cancels the current sleep timer.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _remainingTime = null;
    notifyListeners();
  }

  void _onFinished(CurrentMusicProvider music) {
    cancel();
    if (music.isPlaying) {
      music.pause();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
