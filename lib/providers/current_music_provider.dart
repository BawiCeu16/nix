import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/providers/settings_provider.dart';

/// Loading states for the audio player.
enum AudioLoadingState { idle, loading, loaded, error }

/// Result of a queue operation, used by the UI to show appropriate feedback.
enum QueueResult {
  /// Track was successfully added.
  success,

  /// The track is already in the queue.
  duplicate,

  /// The operation failed for an unexpected reason.
  error,
}

/// Core audio playback engine and state manager.
/// Acts as the BaseAudioHandler for audio_service to enable background playback.
class CurrentMusicProvider extends BaseAudioHandler with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  SettingsProvider? _settingsProvider;

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    // Keep native skip silence in sync
    _audioPlayer.setSkipSilenceEnabled(settings.skipSilence);
  }

  Track? _currentTrack;
  Playlist? _currentPlaylist;
  bool _isShuffleEnabled = false;
  bool _isRepeatEnabled = false;
  
  // Stream for signaling when a track starts playing
  final StreamController<Track> _onTrackPlayedController =
      StreamController<Track>.broadcast();
  Stream<Track> get onTrackPlayedStream => _onTrackPlayedController.stream;

  bool _isTransitioning = false;

  AudioLoadingState _audioLoadingState = AudioLoadingState.idle;
  Color? _dynamicSeedColor;

  // Getters
  Track? get currentTrack => _currentTrack;
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _isRepeatEnabled;
  AudioLoadingState get audioLoading => _audioLoadingState;
  Color? get dynamicSeedColor => _dynamicSeedColor;

  // Legacy API compatibility
  Track? get playing => _currentTrack;
  bool get isPlaying => _audioPlayer.playing;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;
  double get progress => duration != null && duration!.inMilliseconds > 0
      ? position.inMilliseconds / duration!.inMilliseconds
      : 0.0;

  Stream<bool> get isPlayingStream => _audioPlayer.playingStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Future<void> init() async {
    // Set up audio player
    _audioPlayer.setLoopMode(_isRepeatEnabled ? LoopMode.all : LoopMode.off);

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
      notifyListeners();

      // Broadcast state to audio_service
      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (state.playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[state.processingState]!,
          playing: state.playing,
          updatePosition: _audioPlayer.position,
          bufferedPosition: _audioPlayer.bufferedPosition,
          speed: _audioPlayer.speed,
          queueIndex: _currentPlaylist?.tracks.indexOf(_currentTrack!),
        ),
      );
    });

    // Platform-Agnostic 'Smart Skip' Logic
    // Trims the last 3 seconds of a track ONLY if skipSilence is enabled.
    // This provides a "dynamic" transition where the native engine fails.
    _audioPlayer.positionStream.listen((pos) {
      // Opt. #6: Early exit — skip all computation when feature is disabled.
      // This fires ~5 times/second so every avoided comparison matters.
      if (_settingsProvider?.skipSilence != true) return;

      final settings = _settingsProvider;
      if (settings != null) {
        final duration = _audioPlayer.duration;
        if (duration != null && 
            _audioPlayer.playing && 
            !_isTransitioning &&
            _audioPlayer.processingState == ProcessingState.ready) {
          
          final remaining = duration.inMilliseconds - pos.inMilliseconds;
          // Threshold set to 3 seconds (3000ms)
          if (remaining > 0 && remaining < 3000) {
            playNext();
          }
        }
      }
    });

    // Native High-Fidelity Skip Silence (Android only)
    await _audioPlayer.setSkipSilenceEnabled(_settingsProvider?.skipSilence ?? false);
  }

  Future<void> playTrack(Track track, {Playlist? playlist}) async {
    try {
      _audioLoadingState = AudioLoadingState.loading;
      notifyListeners();

      _currentTrack = track;
      _currentPlaylist = playlist ?? _getDefaultPlaylistForTrack(track);

      // Update MediaItem for system notification
      final artworkBytes = await OnAudioQuery().queryArtwork(
        track.id,
        ArtworkType.AUDIO,
      );

      String? artPath;
      if (artworkBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/${track.id}_${artworkBytes.length}.png',
        );
        if (!await file.exists()) {
          await file.writeAsBytes(artworkBytes);
        }
        artPath = file.path;
      }

      final mediaItem = MediaItem(
        id: track.uri,
        album: track.album,
        title: track.title,
        artist: track.artist,
        duration: Duration(milliseconds: track.duration),
        artUri: artPath != null ? Uri.file(artPath) : null,
      );
      this.mediaItem.add(mediaItem);

      // Record play history and count
      try {
        final historyBox = await Hive.openBox<int>(HiveKeys.playHistoryBox);
        await historyBox.put(track.id, DateTime.now().millisecondsSinceEpoch);

        final countsBox = await Hive.openBox<int>(HiveKeys.playCountsBox);
        final currentCount = countsBox.get(track.id, defaultValue: 0) ?? 0;
        await countsBox.put(track.id, currentCount + 1);
      } catch (e) {
        debugPrint('Error recording play history: $e');
      }

      await _audioPlayer.setAudioSource(AudioSource.file(track.uri));
      await _audioPlayer.play();
      _onTrackPlayedController.add(track);

      // Extract colors from artwork for dynamic theming
      if (artworkBytes != null) {
        _updateDynamicSeedColor(artworkBytes);
      } else {
        _dynamicSeedColor = null;
        notifyListeners();
      }

      _audioLoadingState = AudioLoadingState.loaded;
      notifyListeners();

      // Apply saved playback speed
      if (_settingsProvider?.resetSpeedOnNewTrack == true) {
        _settingsProvider?.setPlaybackSpeed(1.0);
      }
      await _audioPlayer.setSpeed(_settingsProvider?.playbackSpeed ?? 1.0);
    } catch (e) {
      _audioLoadingState = AudioLoadingState.error;
      debugPrint('Error playing track: $e');
      notifyListeners();
    } finally {
      // Small delay before clearing transition guard to ensure the new track's
      // position has stabilized and won't re-trigger the skip logic immediately.
      Future.delayed(const Duration(milliseconds: 500), () {
        _isTransitioning = false;
      });
    }
  }

  Future<void> _updateDynamicSeedColor(Uint8List artworkBytes) async {
    try {
      final scheme = await ColorScheme.fromImageProvider(
        provider: MemoryImage(artworkBytes),
      );

      _dynamicSeedColor = scheme.primary;
      notifyListeners();
    } catch (e) {
      debugPrint('Error extracting palette: $e');
    }
  }

  @override
  Future<void> play() async {
    if (_currentTrack != null) {
      await _audioPlayer.play();
    }
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentTrack = null;
    _currentPlaylist = null;
    _audioLoadingState = AudioLoadingState.idle;
    _isTransitioning = false;
    notifyListeners();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
    _settingsProvider?.setPlaybackSpeed(speed);
    notifyListeners();
  }

  @override
  Future<void> skipToNext() async => playNext();

  @override
  Future<void> skipToPrevious() async => playPrevious();

  Future<void> playNext() async {
    if (_currentPlaylist == null || _currentTrack == null || _isTransitioning) {
      return;
    }

    _isTransitioning = true; // Set guard

    if (_isShuffleEnabled && _currentPlaylist!.tracks.length > 1) {
      int nextIndex;
      do {
        nextIndex = math.Random().nextInt(_currentPlaylist!.tracks.length);
      } while (nextIndex == _currentPlaylist!.tracks.indexOf(_currentTrack!));
      await playTrack(
        _currentPlaylist!.tracks[nextIndex],
        playlist: _currentPlaylist,
      );
      return;
    }

    final currentIndex = _currentPlaylist!.tracks.indexOf(_currentTrack!);
    if (currentIndex < _currentPlaylist!.tracks.length - 1) {
      await playTrack(
        _currentPlaylist!.tracks[currentIndex + 1],
        playlist: _currentPlaylist,
      );
    } else if (_isRepeatEnabled) {
      await playTrack(_currentPlaylist!.tracks[0], playlist: _currentPlaylist);
    } else if (_settingsProvider?.autoPlay == true) {
      // Auto-play: pick a random track from the current playlist
      if (_currentPlaylist!.tracks.isNotEmpty) {
        final randomIdx = math.Random().nextInt(_currentPlaylist!.tracks.length);
        await playTrack(
          _currentPlaylist!.tracks[randomIdx],
          playlist: _currentPlaylist,
        );
      }
    } else {
      _isTransitioning = false; // Reset if nothing to play
    }
  }

  Future<void> playPrevious() async {
    if (_currentPlaylist == null || _currentTrack == null) return;

    final currentIndex = _currentPlaylist!.tracks.indexOf(_currentTrack!);
    if (currentIndex > 0) {
      await playTrack(
        _currentPlaylist!.tracks[currentIndex - 1],
        playlist: _currentPlaylist,
      );
    } else if (_isRepeatEnabled) {
      await playTrack(_currentPlaylist!.tracks.last, playlist: _currentPlaylist);
    }
  }

  QueueResult queueNext(Track track) {
    try {
      if (_currentPlaylist == null) {
        _currentPlaylist = _getDefaultPlaylistForTrack(track);
        notifyListeners();
        return QueueResult.success;
      }

      final currentIndex = _currentTrack != null
          ? _currentPlaylist!.tracks.indexOf(_currentTrack!)
          : -1;
      final nextIndex = currentIndex + 1;
      if (nextIndex < _currentPlaylist!.tracks.length &&
          _currentPlaylist!.tracks[nextIndex].id == track.id) {
        return QueueResult.duplicate;
      }

      _currentPlaylist!.tracks.insert(nextIndex, track);
      notifyListeners();
      return QueueResult.success;
    } catch (e) {
      debugPrint('Error in queueNext: $e');
      return QueueResult.error;
    }
  }

  QueueResult appendToQueue(Track track) {
    try {
      if (_currentPlaylist == null) {
        _currentPlaylist = _getDefaultPlaylistForTrack(track);
        notifyListeners();
        return QueueResult.success;
      }

      if (_currentPlaylist!.tracks.isNotEmpty &&
          _currentPlaylist!.tracks.last.id == track.id) {
        return QueueResult.duplicate;
      }

      _currentPlaylist!.tracks.add(track);
      notifyListeners();
      return QueueResult.success;
    } catch (e) {
      debugPrint('Error in appendToQueue: $e');
      return QueueResult.error;
    }
  }

  void removeFromQueue(int index) {
    if (_currentPlaylist != null &&
        index >= 0 &&
        index < _currentPlaylist!.tracks.length) {
      final removedTrack = _currentPlaylist!.tracks.removeAt(index);
      if (removedTrack == _currentTrack) {
        if (_currentPlaylist!.tracks.isNotEmpty) {
          playNext();
        } else {
          stop();
        }
      }
      notifyListeners();
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (_currentPlaylist == null) return;
    final tracks = _currentPlaylist!.tracks;
    if (oldIndex < 0 || oldIndex >= tracks.length) return;
    if (newIndex < 0 || newIndex >= tracks.length) return;
    final track = tracks.removeAt(oldIndex);
    tracks.insert(newIndex, track);
    notifyListeners();
  }

  void clearQueue() {
    if (_currentPlaylist != null) {
      _currentPlaylist!.tracks.clear();
      stop();
    }
  }

  void updatePlaylist(Playlist playlist) {
    _currentPlaylist = playlist;
    notifyListeners();
  }

  Playlist _getDefaultPlaylistForTrack(Track track) {
    return Playlist(
      id: 'single_${track.id}',
      name: track.title,
      tracks: [track],
      createdAt: DateTime.now(),
    );
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
    _audioPlayer.setLoopMode(_isRepeatEnabled ? LoopMode.all : LoopMode.off);
    notifyListeners();
  }

  @override
  void dispose() {
    _onTrackPlayedController.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}
