import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

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
  final OnAudioQuery _audioQuery = OnAudioQuery();
  SettingsProvider? _settingsProvider;

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    // Keep native skip silence in sync
    _audioPlayer.setSkipSilenceEnabled(settings.skipSilence);
  }

  /// Synchronize the playback engine with the full library for Auto-Play capabilities.
  void updateLibrary(List<Track> tracks) {
    _libraryTracks = List.from(tracks);
    notifyListeners();
  }

  Track? _currentTrack;
  Playlist? _currentPlaylist;
  bool _isShuffleEnabled = false;
  bool _isRepeatEnabled = false;
  List<Track> _libraryTracks = [];

  // Stream for signaling when a track starts playing
  final StreamController<Track> _onTrackPlayedController =
      StreamController<Track>.broadcast();
  Stream<Track> get onTrackPlayedStream => _onTrackPlayedController.stream;

  bool _isTransitioning = false;

  AudioLoadingState _audioLoadingState = AudioLoadingState.idle;
  Color? _dynamicSeedColor;

  /// Token used to synchronize background tasks like artwork extraction.
  /// Incremented every time a new track is selected to start playing.
  int _playbackSelectionToken = 0;

  // Getters
  Track? get currentTrack => _currentTrack;
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _isRepeatEnabled;
  AudioLoadingState get audioLoading => _audioLoadingState;
  Color? get dynamicSeedColor => _dynamicSeedColor;

  /// Returns the track that is scheduled to play next.
  Track? get nextTrack {
    if (_currentPlaylist == null || _currentTrack == null) return null;

    final tracks = _currentPlaylist!.tracks;
    final currentIndex = tracks.indexWhere((t) => t.id == _currentTrack!.id);

    // 1. Check for next track in playlist
    if (currentIndex != -1 && currentIndex < tracks.length - 1) {
      return tracks[currentIndex + 1];
    }

    // 2. Check for Repeat
    if (_isRepeatEnabled && tracks.isNotEmpty) {
      return tracks[0];
    }

    // 3. Auto-play logic (simplified, as we don't want to trigger Random repeatedly in a getter)
    // For now, we return null if no explicit next track or repeat, or we could return a placeholder.
    // However, if autoPlay is on, we know SOME track will play.
    return null;
  }

  /// Returns true if a track is loaded and the MiniPlayer should be visible.
  bool get showMiniPlayer => _currentTrack != null;

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

    // Resume from played duration position saving
    _audioPlayer.positionStream.listen((pos) {
      final currentTrack = _currentTrack;
      if (currentTrack != null &&
          _settingsProvider?.resumeFromPlayedDuration == true) {
        final duration = _audioPlayer.duration;
        if (duration != null) {
          final posMs = pos.inMilliseconds;
          final durMs = duration.inMilliseconds;
          final remainingMs = durMs - posMs;
          final positionBox = Hive.box<int>(HiveKeys.trackPositionsBox);

          if (pos.inSeconds > 5 && remainingMs > 5000) {
            final lastSaved = positionBox.get(currentTrack.id);
            if (lastSaved == null || (lastSaved - posMs).abs() >= 1000) {
              positionBox.put(currentTrack.id, posMs);
            }
          } else if (remainingMs <= 5000 || pos.inSeconds <= 5) {
            if (positionBox.containsKey(currentTrack.id)) {
              positionBox.delete(currentTrack.id);
            }
          }
        }
      }
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
    await _audioPlayer.setSkipSilenceEnabled(
      _settingsProvider?.skipSilence ?? false,
    );
  }

  Future<void> playTrack(Track track, {Playlist? playlist}) async {
    // 1. PHASE 1: Immediate State Update (Synchronous-like)
    _playbackSelectionToken++;
    final int currentToken = _playbackSelectionToken;

    try {
      _audioLoadingState = AudioLoadingState.loading;
      _currentTrack = track;
      _currentPlaylist = playlist ?? _getDefaultPlaylistForTrack(track);
      notifyListeners();

      // 2. PHASE 2: Parallel Execution Branches
      // We don't await the background tasks to ensure the audio starts ASAP.

      unawaited(() async {
        try {
          final isNetworkUrl = track.uri.startsWith('http://') || track.uri.startsWith('https://');
          final source = isNetworkUrl ? AudioSource.uri(Uri.parse(track.uri)) : AudioSource.file(track.uri);
          
          Duration? initialPosition;
          if (_settingsProvider?.resumeFromPlayedDuration == true) {
            final positionBox = Hive.box<int>(HiveKeys.trackPositionsBox);
            final savedMs = positionBox.get(track.id);
            if (savedMs != null) {
              initialPosition = Duration(milliseconds: savedMs);
            }
          }

          await _audioPlayer.setAudioSource(source, initialPosition: initialPosition);
          if (currentToken == _playbackSelectionToken) {
            await _audioPlayer.play();
            _audioLoadingState = AudioLoadingState.loaded;
            notifyListeners();
          }
        } catch (e) {
          if (currentToken == _playbackSelectionToken) {
            _audioLoadingState = AudioLoadingState.error;
            notifyListeners();
          }
          debugPrint('Audio branch error: $e');
        }
      }());

      // Branch B: Theming & Visuals (Parallel)
      _updateDynamicSeedColorForTrack(track, currentToken);

      // Branch C: Metadata & System Integration (Parallel)
      unawaited(() async {
        try {
          final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
          Uint8List? artworkBytes;
          if (isMobile) {
            artworkBytes = await _audioQuery.queryArtwork(
              track.id,
              ArtworkType.AUDIO,
            );
          }

          if (currentToken != _playbackSelectionToken) return;

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

          if (currentToken == _playbackSelectionToken) {
            final mediaItem = MediaItem(
              id: track.uri,
              album: track.album,
              title: track.title,
              artist: track.artist,
              duration: Duration(milliseconds: track.duration),
              artUri: artPath != null ? Uri.file(artPath) : null,
            );
            this.mediaItem.add(mediaItem);
          }
        } catch (e) {
          debugPrint('Metadata branch error: $e');
        }
      }());

      // Branch D: History & Persistence (Fire-and-forget)
      unawaited(() async {
        try {
          final historyBox = Hive.box<int>(HiveKeys.playHistoryBox);
          await historyBox.put(track.id, DateTime.now().millisecondsSinceEpoch);

          final countsBox = Hive.box<int>(HiveKeys.playCountsBox);
          final currentCount = countsBox.get(track.id, defaultValue: 0) ?? 0;
          await countsBox.put(track.id, currentCount + 1);

          if (currentToken == _playbackSelectionToken) {
            _onTrackPlayedController.add(track);
          }
        } catch (e) {
          debugPrint('History branch error: $e');
        }
      }());

      // 3. PHASE 3: Post-playback adjustments
      // Apply speed from settings AFTER the player has started
      if (_settingsProvider?.resetSpeedOnNewTrack == true) {
        _settingsProvider?.setPlaybackSpeed(1.0);
      }
      _audioPlayer.setSpeed(_settingsProvider?.playbackSpeed ?? 1.0);
    } catch (e) {
      debugPrint('Global playTrack error: $e');
      _audioLoadingState = AudioLoadingState.error;
      notifyListeners();
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (currentToken == _playbackSelectionToken) {
          _isTransitioning = false;
        }
      });
    }
  }

  /// Optimized color extraction for dynamic theming.
  /// Checks persistent cache first, falls back to low-quality artwork query.
  Future<void> _updateDynamicSeedColorForTrack(
    Track track,
    int? requestToken,
  ) async {
    final cache = Hive.box<int>(HiveKeys.colorCacheBox);
    final cachedColor = cache.get(track.id);

    if (cachedColor != null) {
      // Guard: Only apply if this is still the current request
      if (requestToken != null && requestToken != _playbackSelectionToken) {
        return;
      }

      _dynamicSeedColor = Color(cachedColor);
      notifyListeners();
      return;
    }

    try {
      final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      Uint8List? extractBytes;
      if (isMobile) {
        extractBytes = await _audioQuery.queryArtwork(
          track.id,
          ArtworkType.AUDIO,
          size: 100,
        );
      }

      // Guard: Check token after async boundary
      if (requestToken != null && requestToken != _playbackSelectionToken) {
        return;
      }

      if (extractBytes != null) {
        final scheme = await ColorScheme.fromImageProvider(
          provider: MemoryImage(extractBytes),
        );

        // Final guard before updating state
        if (requestToken != null && requestToken != _playbackSelectionToken) {
          return;
        }

        _dynamicSeedColor = scheme.primary;
        await cache.put(track.id, _dynamicSeedColor!.toARGB32());
        notifyListeners();
      } else {
        if (requestToken == null || requestToken == _playbackSelectionToken) {
          _dynamicSeedColor = null;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error extracting palette for ${track.id}: $e');
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
      // Auto-play: pick a random track from the ENTIRE library that isn't the current one
      if (_libraryTracks.isNotEmpty) {
        Track nextTrack;
        if (_libraryTracks.length > 1) {
          do {
            nextTrack =
                _libraryTracks[math.Random().nextInt(_libraryTracks.length)];
          } while (nextTrack.id == _currentTrack?.id);
        } else {
          nextTrack = _libraryTracks[0];
        }

        await playTrack(nextTrack);
      } else {
        _isTransitioning = false;
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
      await playTrack(
        _currentPlaylist!.tracks.last,
        playlist: _currentPlaylist,
      );
    }
  }

  QueueResult queueNext(Track track) {
    try {
      if (_currentPlaylist == null) {
        _currentPlaylist = _getDefaultPlaylistForTrack(track);
        notifyListeners();
        return QueueResult.success;
      }

      // GLOBAL Duplicate check
      if (_currentPlaylist!.tracks.any((t) => t.id == track.id)) {
        return QueueResult.duplicate;
      }

      final currentIndex = _currentTrack != null
          ? _currentPlaylist!.tracks.indexOf(_currentTrack!)
          : -1;
      final nextIndex = currentIndex + 1;

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

      // GLOBAL Duplicate check
      if (_currentPlaylist!.tracks.any((t) => t.id == track.id)) {
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

  /// Moves an existing track in the queue to the 'Play Next' position.
  void moveTrackToPlayNext(Track track) {
    if (_currentPlaylist == null) return;

    final index = _currentPlaylist!.tracks.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      final t = _currentPlaylist!.tracks.removeAt(index);
      final currentIndex = _currentTrack != null
          ? _currentPlaylist!.tracks.indexOf(_currentTrack!)
          : -1;
      _currentPlaylist!.tracks.insert(currentIndex + 1, t);
      notifyListeners();
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

  void shuffleQueue() {
    if (_currentPlaylist != null && _currentPlaylist!.tracks.isNotEmpty) {
      _currentPlaylist!.tracks.shuffle();
      notifyListeners();
    }
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
