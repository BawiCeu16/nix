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

import '../models/music/song.dart';
import '../models/music/playlist.dart';
import '../core/hive_keys.dart';
import '../providers/settings_provider.dart';

/// Loading states for the audio player.
enum AudioLoadingState { idle, loading, loaded, error }

/// Result of a queue operation, used by the UI to show appropriate feedback.
enum QueueResult {
  /// Song was successfully added.
  success,

  /// The song is already in the queue.
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
  }

  Song? _currentSong;
  Playlist? _currentPlaylist;
  bool _isShuffleEnabled = false;
  bool _isRepeatEnabled = false;
  // Stream for signaling when a song starts playing
  final StreamController<Song> _onSongPlayedController =
      StreamController<Song>.broadcast();
  Stream<Song> get onSongPlayedStream => _onSongPlayedController.stream;

  AudioLoadingState _audioLoadingState = AudioLoadingState.idle;
  Color? _dynamicSeedColor;

  // Getters
  Song? get currentSong => _currentSong;
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _isRepeatEnabled;
  AudioLoadingState get audioLoading => _audioLoadingState;
  Color? get dynamicSeedColor => _dynamicSeedColor;

  // Legacy API compatibility
  Song? get playing => _currentSong;
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
          queueIndex: _currentPlaylist?.songs.indexOf(_currentSong!),
        ),
      );
    });
  }

  Future<void> playSong(Song song, {Playlist? playlist}) async {
    try {
      _audioLoadingState = AudioLoadingState.loading;
      notifyListeners();

      _currentSong = song;
      _currentPlaylist = playlist ?? _getDefaultPlaylistForSong(song);

      // Update MediaItem for system notification
      final artworkBytes = await OnAudioQuery().queryArtwork(
        song.id,
        ArtworkType.AUDIO,
      );

      String? artPath;
      if (artworkBytes != null) {
        final tempDir = await getTemporaryDirectory();
        // Use a hash of the artwork bytes in the filename to ensure
        // the system media notification doesn't cache a stale or wrong image
        // for the same song ID.
        final file = File(
          '${tempDir.path}/${song.id}_${artworkBytes.length}.png',
        );
        if (!await file.exists()) {
          await file.writeAsBytes(artworkBytes);
        }
        artPath = file.path;
      }

      final mediaItem = MediaItem(
        id: song.uri,
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: Duration(milliseconds: song.duration),
        artUri: artPath != null ? Uri.file(artPath) : null,
      );
      this.mediaItem.add(mediaItem);

      // Record play history and count
      try {
        final historyBox = await Hive.openBox<int>(HiveKeys.playHistoryBox);
        await historyBox.put(song.id, DateTime.now().millisecondsSinceEpoch);

        final countsBox = await Hive.openBox<int>(HiveKeys.playCountsBox);
        final currentCount = countsBox.get(song.id, defaultValue: 0) ?? 0;
        await countsBox.put(song.id, currentCount + 1);
      } catch (e) {
        debugPrint('Error recording play history: $e');
      }

      await _audioPlayer.setAudioSource(AudioSource.file(song.uri));
      await _audioPlayer.play();
      _onSongPlayedController.add(song);

      // Extract colors from artwork for dynamic theming
      if (artworkBytes != null) {
        _updateDynamicSeedColor(artworkBytes);
      } else {
        _dynamicSeedColor = null;
        notifyListeners();
      }

      _audioLoadingState = AudioLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _audioLoadingState = AudioLoadingState.error;
      debugPrint('Error playing song: $e');
      notifyListeners();
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
    if (_currentSong != null) {
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
    _currentSong = null;
    _currentPlaylist = null;
    _audioLoadingState = AudioLoadingState.idle;
    notifyListeners();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async => playNext();

  @override
  Future<void> skipToPrevious() async => playPrevious();

  Future<void> playNext() async {
    if (_currentPlaylist == null || _currentSong == null) return;

    if (_isShuffleEnabled && _currentPlaylist!.songs.length > 1) {
      int nextIndex;
      do {
        nextIndex = math.Random().nextInt(_currentPlaylist!.songs.length);
      } while (nextIndex == _currentPlaylist!.songs.indexOf(_currentSong!));
      await playSong(
        _currentPlaylist!.songs[nextIndex],
        playlist: _currentPlaylist,
      );
      return;
    }

    final currentIndex = _currentPlaylist!.songs.indexOf(_currentSong!);
    if (currentIndex < _currentPlaylist!.songs.length - 1) {
      await playSong(
        _currentPlaylist!.songs[currentIndex + 1],
        playlist: _currentPlaylist,
      );
    } else if (_isRepeatEnabled) {
      await playSong(_currentPlaylist!.songs[0], playlist: _currentPlaylist);
    } else if (_settingsProvider?.autoPlay == true) {
      // Auto-play: pick a random track from the current playlist
      if (_currentPlaylist!.songs.isNotEmpty) {
        final randomIdx = math.Random().nextInt(_currentPlaylist!.songs.length);
        await playSong(
          _currentPlaylist!.songs[randomIdx],
          playlist: _currentPlaylist,
        );
      }
    }
  }

  Future<void> playPrevious() async {
    if (_currentPlaylist == null || _currentSong == null) return;

    final currentIndex = _currentPlaylist!.songs.indexOf(_currentSong!);
    if (currentIndex > 0) {
      await playSong(
        _currentPlaylist!.songs[currentIndex - 1],
        playlist: _currentPlaylist,
      );
    } else if (_isRepeatEnabled) {
      await playSong(_currentPlaylist!.songs.last, playlist: _currentPlaylist);
    }
  }

  /// Inserts [song] immediately after the currently playing track.
  ///
  /// Returns a [QueueResult] so the UI can show contextual feedback.
  QueueResult queueNext(Song song) {
    try {
      if (_currentPlaylist == null) {
        _currentPlaylist = _getDefaultPlaylistForSong(song);
        notifyListeners();
        return QueueResult.success;
      }

      // Check for duplicate – skip if already queued right after current
      final currentIndex = _currentSong != null
          ? _currentPlaylist!.songs.indexOf(_currentSong!)
          : -1;
      final nextIndex = currentIndex + 1;
      if (nextIndex < _currentPlaylist!.songs.length &&
          _currentPlaylist!.songs[nextIndex].id == song.id) {
        return QueueResult.duplicate;
      }

      _currentPlaylist!.songs.insert(nextIndex, song);
      notifyListeners();
      return QueueResult.success;
    } catch (e) {
      debugPrint('Error in queueNext: $e');
      return QueueResult.error;
    }
  }

  /// Appends [song] to the end of the current queue.
  ///
  /// Returns a [QueueResult] so the UI can show contextual feedback.
  QueueResult appendToQueue(Song song) {
    try {
      if (_currentPlaylist == null) {
        _currentPlaylist = _getDefaultPlaylistForSong(song);
        notifyListeners();
        return QueueResult.success;
      }

      // Check for duplicate at the end of the queue
      if (_currentPlaylist!.songs.isNotEmpty &&
          _currentPlaylist!.songs.last.id == song.id) {
        return QueueResult.duplicate;
      }

      _currentPlaylist!.songs.add(song);
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
        index < _currentPlaylist!.songs.length) {
      final removedSong = _currentPlaylist!.songs.removeAt(index);
      if (removedSong == _currentSong) {
        if (_currentPlaylist!.songs.isNotEmpty) {
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
    final songs = _currentPlaylist!.songs;
    if (oldIndex < 0 || oldIndex >= songs.length) return;
    if (newIndex < 0 || newIndex >= songs.length) return;
    final song = songs.removeAt(oldIndex);
    songs.insert(newIndex, song);
    notifyListeners();
  }

  void clearQueue() {
    if (_currentPlaylist != null) {
      _currentPlaylist!.songs.clear();
      stop();
    }
  }

  void updatePlaylist(Playlist playlist) {
    _currentPlaylist = playlist;
    notifyListeners();
  }

  Playlist _getDefaultPlaylistForSong(Song song) {
    return Playlist(
      id: 'single_${song.id}',
      name: song.title,
      songs: [song],
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
    _onSongPlayedController.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}
