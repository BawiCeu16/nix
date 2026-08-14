import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:nix/core/hive_keys.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/providers/music_provider.dart';
import 'package:nix/providers/current_music_provider.dart';
import 'package:nix/ui/screens/music/artists_page.dart';

class TrackStat {
  final Track track;
  final int playCount;
  final DateTime? lastPlayed;

  const TrackStat({
    required this.track,
    required this.playCount,
    this.lastPlayed,
  });
}

class ArtistStat {
  final String artistName;
  final int totalPlayCount;
  final int trackCount;

  const ArtistStat({
    required this.artistName,
    required this.totalPlayCount,
    required this.trackCount,
  });
}

class HistoryStat {
  final Track track;
  final DateTime lastPlayed;

  const HistoryStat({
    required this.track,
    required this.lastPlayed,
  });
}

class StatsController extends ChangeNotifier {
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  List<TrackStat> _topSongs = [];
  List<ArtistStat> _topArtists = [];
  List<HistoryStat> _playbackHistory = [];

  int _totalPlayCount = 0;
  Duration _totalListeningTime = Duration.zero;
  int _uniqueArtistsCount = 0;

  StreamSubscription<Track>? _trackPlayedSubscription;
  StreamSubscription<BoxEvent>? _playCountsSubscription;
  StreamSubscription<BoxEvent>? _playHistorySubscription;
  StreamSubscription<BoxEvent>? _playDurationsSubscription;
  MusicProvider? _musicProvider;

  List<TrackStat> get topSongs => _topSongs;
  List<ArtistStat> get topArtists => _topArtists;
  List<HistoryStat> get playbackHistory => _playbackHistory;

  int get totalPlayCount => _totalPlayCount;
  Duration get totalListeningTime => _totalListeningTime;
  int get uniqueArtistsCount => _uniqueArtistsCount;
  TrackStat? get topSong => _topSongs.isNotEmpty ? _topSongs.first : null;
  ArtistStat? get topArtist => _topArtists.isNotEmpty ? _topArtists.first : null;

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  List<TrackStat> get sortedTopSongs => _topSongs;
  List<ArtistStat> get sortedTopArtists => _topArtists;
  List<HistoryStat> get sortedPlaybackHistory => _playbackHistory;

  /// Initialize real-time listeners for automatic stats refresh
  void init(MusicProvider musicProvider, CurrentMusicProvider currentMusicProvider) {
    _musicProvider = musicProvider;
    calculateStats();

    // 1. Listen to when a track starts playing
    _trackPlayedSubscription = currentMusicProvider.onTrackPlayedStream.listen((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        calculateStats();
      });
    });

    // 2. Listen to Hive Box changes for real-time play counts, history, and duration updates
    if (Hive.isBoxOpen(HiveKeys.playCountsBox)) {
      _playCountsSubscription = Hive.box<int>(HiveKeys.playCountsBox).watch().listen((_) {
        calculateStats();
      });
    }

    if (Hive.isBoxOpen(HiveKeys.playHistoryBox)) {
      _playHistorySubscription = Hive.box<int>(HiveKeys.playHistoryBox).watch().listen((_) {
        calculateStats();
      });
    }

    if (Hive.isBoxOpen(HiveKeys.playDurationsBox)) {
      _playDurationsSubscription = Hive.box<int>(HiveKeys.playDurationsBox).watch().listen((_) {
        calculateStats();
      });
    }
  }

  void calculateStats([MusicProvider? musicProvider]) {
    final music = musicProvider ?? _musicProvider;
    if (music == null) return;

    final allTracks = music.tracks;
    final trackMap = {for (final t in allTracks) t.id: t};

    // 1. Play Counts
    final Map<int, int> playCounts = {};
    if (Hive.isBoxOpen(HiveKeys.playCountsBox)) {
      final box = Hive.box<int>(HiveKeys.playCountsBox);
      for (final key in box.keys) {
        if (key is int) {
          final count = box.get(key) ?? 0;
          if (count > 0) playCounts[key] = count;
        }
      }
    }

    // 2. History Timestamps
    final Map<int, int> historyTimestamps = {};
    if (Hive.isBoxOpen(HiveKeys.playHistoryBox)) {
      final box = Hive.box<int>(HiveKeys.playHistoryBox);
      for (final key in box.keys) {
        if (key is int) {
          final ts = box.get(key) ?? 0;
          if (ts > 0) historyTimestamps[key] = ts;
        }
      }
    }

    // 3. Actual Play Durations (in ms)
    final Map<int, int> actualPlayDurations = {};
    if (Hive.isBoxOpen(HiveKeys.playDurationsBox)) {
      final box = Hive.box<int>(HiveKeys.playDurationsBox);
      for (final key in box.keys) {
        if (key is int) {
          final ms = box.get(key) ?? 0;
          if (ms > 0) actualPlayDurations[key] = ms;
        }
      }
    }

    // --- Process Top Songs & Actual Listening Time ---
    final List<TrackStat> songStats = [];
    int sumPlays = 0;
    int totalMsListened = 0;

    playCounts.forEach((trackId, count) {
      final track = trackMap[trackId];
      if (track != null) {
        sumPlays += count;

        // Use exact actual recorded listen duration if available, else estimate from track.duration * count
        final recordedMs = actualPlayDurations[trackId];
        totalMsListened += recordedMs ?? (track.duration * count);

        final ts = historyTimestamps[trackId];
        songStats.add(
          TrackStat(
            track: track,
            playCount: count,
            lastPlayed: ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null,
          ),
        );
      }
    });

    songStats.sort((a, b) => b.playCount.compareTo(a.playCount));
    _topSongs = songStats;
    _totalPlayCount = sumPlays;
    _totalListeningTime = Duration(milliseconds: totalMsListened);

    // --- Process Top Artists ---
    final Map<String, int> artistPlays = {};
    final Map<String, Set<int>> artistTrackIds = {};

    for (final stat in songStats) {
      final artist = stat.track.artist.trim();
      if (artist.isEmpty || artist == '<unknown>') continue;

      artistPlays[artist] = (artistPlays[artist] ?? 0) + stat.playCount;
      artistTrackIds.putIfAbsent(artist, () => {}).add(stat.track.id);
    }

    final List<ArtistStat> artistStats = artistPlays.entries.map((e) {
      return ArtistStat(
        artistName: e.key,
        totalPlayCount: e.value,
        trackCount: artistTrackIds[e.key]?.length ?? 0,
      );
    }).toList();

    artistStats.sort((a, b) => b.totalPlayCount.compareTo(a.totalPlayCount));
    _topArtists = artistStats;
    _uniqueArtistsCount = artistStats.length;

    // --- Process History ---
    final List<HistoryStat> historyList = [];
    historyTimestamps.forEach((trackId, ts) {
      final track = trackMap[trackId];
      if (track != null) {
        historyList.add(
          HistoryStat(
            track: track,
            lastPlayed: DateTime.fromMillisecondsSinceEpoch(ts),
          ),
        );
      }
    });

    historyList.sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
    _playbackHistory = historyList;

    notifyListeners();
  }

  int? getFirstTrackIdForArtist(String artistName) {
    final tracks = _musicProvider?.tracks;
    if (tracks == null) return null;
    for (final t in tracks) {
      if (t.artist.trim().toLowerCase() == artistName.trim().toLowerCase()) {
        return t.id;
      }
    }
    return null;
  }

  void openArtistDetails(BuildContext context, String artistName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistTracksPage(artistName: artistName),
      ),
    );
  }

  void playTrack(
    BuildContext context,
    Track track, [
    List<Track>? playlistContext,
  ]) {
    final player = context.read<CurrentMusicProvider>();
    final playlist = playlistContext != null && playlistContext.isNotEmpty
        ? Playlist(
            id: 'stats_playlist',
            name: 'Listening Stats',
            tracks: playlistContext,
            createdAt: DateTime.now(),
          )
        : null;
    player.playTrack(track, playlist: playlist);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else if (duration.inSeconds > 0) {
      return '${duration.inSeconds}s';
    } else {
      return '0m';
    }
  }

  static String formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  static String formatDateAdded(int dateAdded) {
    if (dateAdded <= 0) return 'Unknown';
    // If in seconds (< 100000000000), convert to ms
    final ms = dateAdded < 100000000000 ? dateAdded * 1000 : dateAdded;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  void dispose() {
    _trackPlayedSubscription?.cancel();
    _playCountsSubscription?.cancel();
    _playHistorySubscription?.cancel();
    _playDurationsSubscription?.cancel();
    super.dispose();
  }
}
