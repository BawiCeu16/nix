import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/models/music/album.dart';
import 'package:nix/models/music/artist.dart';
import 'package:nix/core/hive_keys.dart';

/// Input parameters for isolate library parsing.
class LibraryParseInput {
  final List<Map<String, dynamic>> rawSongs;
  const LibraryParseInput(this.rawSongs);
}

/// Parsed result bundle from background isolate.
class LibraryParseOutput {
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final Map<String, int> albumFirstTrackId;

  const LibraryParseOutput(
    this.tracks,
    this.albums,
    this.artists,
    this.albumFirstTrackId,
  );
}

/// Top-level isolate worker function for parsing raw MediaStore audio maps.
LibraryParseOutput parseLibraryInIsolate(LibraryParseInput input) {
  final rawSongs = input.rawSongs;

  final tracks = rawSongs.map((raw) {
    return Track(
      dateAdded: raw['dateAdded'] as int? ?? 0,
      id: raw['id'] as int,
      title: raw['title'] as String,
      artist: raw['artist'] as String? ?? '<Unknown>',
      album: raw['album'] as String? ?? '<Unknown>',
      uri: raw['uri'] as String,
      duration: raw['duration'] as int? ?? 0,
      size: raw['size'] as int? ?? 0,
    );
  }).toList();

  final albumMap = <String, List<Track>>{};
  final artistMap = <String, List<Track>>{};
  for (final track in tracks) {
    albumMap.putIfAbsent(track.album, () => []).add(track);
    artistMap.putIfAbsent(track.artist, () => []).add(track);
  }

  var albumIdx = 0;
  final albums = albumMap.entries.map((entry) {
    return Album(
      id: albumIdx++,
      title: entry.key,
      artist: entry.value.first.artist,
      numOfSongs: entry.value.length,
    );
  }).toList();

  var artistIdx = 0;
  final artists = artistMap.entries.map((entry) {
    return Artist(
      id: artistIdx++,
      name: entry.key,
      numberOfAlbums: albumMap.values
          .where((tList) => tList.first.artist == entry.key)
          .length,
      numberOfTracks: entry.value.length,
    );
  }).toList();

  final albumFirstTrackId = <String, int>{};
  for (final track in tracks) {
    albumFirstTrackId.putIfAbsent(track.album, () => track.id);
  }

  return LibraryParseOutput(tracks, albums, artists, albumFirstTrackId);
}

/// Encapsulates native MediaStore scanning, permission requests, and isolate parsing.
class MediaLibraryService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Scans the device (or loads mock data on desktop/web) for music tracks and metadata.
  Future<LibraryParseOutput> scanDevice({List<String>? customFolders}) async {
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    bool permissionStatus = false;
    if (!isMobile) {
      permissionStatus = true;
    } else if (Platform.isIOS) {
      permissionStatus = await _audioQuery.permissionsStatus();
      if (!permissionStatus) {
        permissionStatus = await _audioQuery.permissionsRequest();
      }
    } else {
      final results = await Future.wait([
        Permission.audio.request(),
        Permission.storage.request(),
      ]);
      permissionStatus = results.any((status) => status.isGranted);
    }

    if (!permissionStatus) {
      throw Exception('Storage permission not granted. Cannot scan music.');
    }

    if (!isMobile) {
      return _generateMockData();
    }

    final audioList = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    final settingsBox = Hive.box(HiveKeys.settingsBox);
    final int minDurationSeconds =
        settingsBox.get(HiveKeys.minDuration, defaultValue: 0) ?? 0;
    final int minDurationMs = minDurationSeconds * 1000;

    final validAudio = audioList.where((item) {
      final bool isAcceptedType =
          item.isMusic == true || item.isPodcast == true;
      final bool isLongEnough = (item.duration ?? 0) >= minDurationMs;
      return isAcceptedType && isLongEnough;
    }).toList();

    final rawSongs = validAudio
        .map(
          (audio) => <String, dynamic>{
            'dateAdded': audio.dateAdded ?? 0,
            'id': audio.id,
            'title': audio.title,
            'artist': audio.artist,
            'album': audio.album,
            'uri': audio.data,
            'duration': audio.duration ?? 0,
            'size': audio.size,
          },
        )
        .toList();

    return compute(parseLibraryInIsolate, LibraryParseInput(rawSongs));
  }

  /// Generates mock tracks for non-mobile platforms (desktop / web debugging).
  LibraryParseOutput _generateMockData() {
    final tracks = [
      Track(
        id: 1,
        title: 'Helix Song 1',
        artist: 'SoundHelix',
        album: 'Helix Odyssey',
        uri: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        duration: 372000,
        dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      Track(
        id: 2,
        title: 'Helix Song 2',
        artist: 'SoundHelix',
        album: 'Helix Odyssey',
        uri: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        duration: 423000,
        dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      Track(
        id: 3,
        title: 'Helix Song 3',
        artist: 'SoundHelix',
        album: 'Helix Odyssey',
        uri: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        duration: 344000,
        dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      Track(
        id: 4,
        title: 'Helix Song 4',
        artist: 'SoundHelix',
        album: 'Helix Odyssey',
        uri: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        duration: 302000,
        dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      Track(
        id: 5,
        title: 'Acoustic Breeze',
        artist: 'Bensound',
        album: 'Bensound Breeze',
        uri: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        duration: 280000,
        dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      Track(
        id: 6,
        title: 'Summer Vibes',
        artist: 'Bensound',
        album: 'Bensound Breeze',
        uri: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
        duration: 310000,
        dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    ];

    final albumMap = <String, List<Track>>{};
    final artistMap = <String, List<Track>>{};
    for (final track in tracks) {
      albumMap.putIfAbsent(track.album, () => []).add(track);
      artistMap.putIfAbsent(track.artist, () => []).add(track);
    }

    var albumIdx = 0;
    final albums = albumMap.entries.map((entry) {
      return Album(
        id: albumIdx++,
        title: entry.key,
        artist: entry.value.first.artist,
        numOfSongs: entry.value.length,
      );
    }).toList();

    var artistIdx = 0;
    final artists = artistMap.entries.map((entry) {
      return Artist(
        id: artistIdx++,
        name: entry.key,
        numberOfAlbums: albumMap.values
            .where((tList) => tList.first.artist == entry.key)
            .length,
        numberOfTracks: entry.value.length,
      );
    }).toList();

    final albumFirstTrackId = <String, int>{};
    for (final track in tracks) {
      albumFirstTrackId.putIfAbsent(track.album, () => track.id);
    }

    return LibraryParseOutput(tracks, albums, artists, albumFirstTrackId);
  }
}
