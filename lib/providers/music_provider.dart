import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart' as amr;
import 'package:hive/hive.dart';
import '../models/music/song.dart';
import '../models/music/album.dart';
import '../models/music/artist.dart';
import '../models/music/playlist.dart';
import '../models/music/images.dart';

class MusicProvider extends ChangeNotifier {
  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  final List<Playlist> _playlists = [];

  bool _isLoading = false;
  bool _hasScanned = false;
  String? _error;

  // Getters
  List<Song> get songs => _songs;
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<Playlist> get playlists => _playlists;

  Playlist get recentlyPlayed {
    if (!Hive.isBoxOpen('play_history')) {
      return Playlist(
        id: 'recently_played',
        name: 'Recently Listened',
        songs: [],
        createdAt: DateTime.now(),
      );
    }
    final historyBox = Hive.box<int>('play_history');
    final history = historyBox.toMap();
    final sortedEntries = history.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recentSongIds = sortedEntries.take(50).map((e) => e.key).toSet();
    final recentSongs = _songs
        .where((s) => recentSongIds.contains(s.id))
        .toList();

    recentSongs.sort((a, b) {
      final timeA = historyBox.get(a.id) ?? 0;
      final timeB = historyBox.get(b.id) ?? 0;
      return timeB.compareTo(timeA);
    });

    return Playlist(
      id: 'recently_played',
      name: 'Recently Listened',
      songs: recentSongs,
      createdAt: DateTime.now(),
    );
  }

  Playlist get topPlayed {
    if (!Hive.isBoxOpen('play_counts')) {
      return Playlist(
        id: 'top_played',
        name: 'Most Played',
        songs: [],
        createdAt: DateTime.now(),
      );
    }
    final countsBox = Hive.box<int>('play_counts');
    final counts = countsBox.toMap();
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topSongIds = sortedEntries.take(50).map((e) => e.key).toSet();
    final topSongs = _songs.where((s) => topSongIds.contains(s.id)).toList();

    topSongs.sort((a, b) {
      final countA = countsBox.get(a.id) ?? 0;
      final countB = countsBox.get(b.id) ?? 0;
      return countB.compareTo(countA);
    });

    return Playlist(
      id: 'top_played',
      name: 'Top Listened',
      songs: topSongs,
      createdAt: DateTime.now(),
    );
  }

  Playlist get favorites {
    if (!Hive.isBoxOpen('favorites')) {
      return Playlist(
        id: 'favorites',
        name: 'Favorites',
        songs: [],
        createdAt: DateTime.now(),
      );
    }
    final favoritesBox = Hive.box<int>('favorites');
    // Keys are song IDs, values are timestamps (millisSinceEpoch)
    final entries = favoritesBox.toMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // latest first
    final orderedIds = entries.map((e) => e.key as int).toList();
    final songMap = {for (final s in _songs) s.id: s};
    final favoriteSongs = orderedIds
        .where((id) => songMap.containsKey(id))
        .map((id) => songMap[id]!)
        .toList();

    return Playlist(
      id: 'favorites',
      name: 'Favorites',
      songs: favoriteSongs,
      createdAt: DateTime.now(),
    );
  }

  bool get isLoading => _isLoading;
  bool get hasScanned => _hasScanned;
  String? get error => _error;

  Future<void> init({List<String>? customFolders}) async {
    await Hive.openBox<int>('favorites');
    await Hive.openBox<String>('playlists');
    await Hive.openBox<int>('play_history');
    await Hive.openBox<int>('play_counts');
    await scanDevice(customFolders: customFolders);
  }

  Future<void> scanDevice({List<String>? customFolders}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final directories = await _getMusicDirectories(customFolders);
      final audioFiles = <File>[];

      for (final dir in directories) {
        if (await dir.exists()) {
          audioFiles.addAll(await _scanDirectoryForAudioFiles(dir));
        }
      }

      // Convert files to songs
      _songs = await _convertFilesToSongs(audioFiles);

      // Group songs into albums and artists
      _createAlbumsAndArtists();

      // Load user playlists
      _loadPlaylists();

      _hasScanned = true;
    } catch (e) {
      _error = 'Failed to scan device: $e';
      debugPrint('Error scanning device: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Directory>> _getMusicDirectories(
    List<String>? customFolders,
  ) async {
    final directories = <Directory>[];

    // Common music directories
    if (Platform.isAndroid) {
      directories.addAll([
        Directory('/storage/emulated/0/Music'),
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/DCIM'),
      ]);

      // Try to get external storage directories
      try {
        final externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null) {
          for (final dir in externalDirs) {
            directories.add(dir);
          }
        }
      } catch (e) {
        debugPrint('Error getting external directories: $e');
      }
    } else if (Platform.isIOS) {
      final documentsDir = await getApplicationDocumentsDirectory();
      directories.add(Directory('${documentsDir.path}/Music'));
    }

    if (customFolders != null && customFolders.isNotEmpty) {
      for (final path in customFolders) {
        final dir = Directory(path);
        // Avoid adding duplicates
        if (!directories.any((d) => d.path == dir.path)) {
          directories.add(dir);
        }
      }
    }

    return directories;
  }

  Future<List<File>> _scanDirectoryForAudioFiles(Directory directory) async {
    final audioFiles = <File>[];
    final audioExtensions = ['.mp3', '.m4a', '.aac', '.ogg', '.wav', '.flac'];

    try {
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final extension = entity.path.toLowerCase();
          if (audioExtensions.any((ext) => extension.endsWith(ext))) {
            audioFiles.add(entity);
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory ${directory.path}: $e');
    }

    return audioFiles;
  }

  Future<List<Song>> _convertFilesToSongs(List<File> files) async {
    final songs = <Song>[];
    final box = await Hive.openBox("cached_images");

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        final metadata = amr.readMetadata(file, getImage: true);

        String title =
            metadata.title ?? file.path.split('/').last.split('.').first;
        String artist = metadata.artist ?? 'Unknown Artist';
        String album = metadata.album ?? 'Unknown Album';
        int duration = metadata.duration?.inMilliseconds ?? 0;

        // Save artwork to Hive if available
        if (metadata.pictures.isNotEmpty) {
          final picture = metadata.pictures.first;
          await box.put(file.path, picture.bytes);
        }

        final song = Song(
          id: i,
          title: title,
          artist: artist,
          album: album,
          uri: file.path,
          duration: duration,
          size: await file.length(),
        );

        songs.add(song);
      } catch (e) {
        debugPrint('Error processing file ${file.path}: $e');
        // Fallback to basic info if metadata reading fails
        final fileName = file.path.split('/').last;
        final nameWithoutExtension = fileName.split('.').first;

        songs.add(
          Song(
            id: i,
            title: nameWithoutExtension,
            artist: 'Unknown Artist',
            album: 'Unknown Album',
            uri: file.path,
            duration: 0,
            size: await file.length(),
          ),
        );
      }
    }

    return songs;
  }

  void _createAlbumsAndArtists() {
    final albumMap = <String, List<Song>>{};
    final artistMap = <String, List<Song>>{};

    for (final song in _songs) {
      // Group by album
      if (!albumMap.containsKey(song.album)) {
        albumMap[song.album] = [];
      }
      albumMap[song.album]!.add(song);

      // Group by artist
      if (!artistMap.containsKey(song.artist)) {
        artistMap[song.artist] = [];
      }
      artistMap[song.artist]!.add(song);
    }

    final Map<String, Album> createdAlbums = {};
    albumMap.forEach((albumTitle, songsInAlbum) {
      Images? albumImages;

      // Use the first song's artwork for the album
      if (songsInAlbum.isNotEmpty) {
        albumImages = Images(sources: {'default': songsInAlbum.first.uri});
      }

      final album = Album(
        id: createdAlbums.length,
        title: albumTitle,
        artist: songsInAlbum.first.artist,
        numOfSongs: songsInAlbum.length,
        images: albumImages,
      );
      createdAlbums[albumTitle] = album;
    });
    _albums = createdAlbums.values.toList();

    final Map<String, Artist> createdArtists = {};
    artistMap.forEach((artistName, songsByArtist) {
      final artist = Artist(
        id: createdArtists.length,
        name: artistName,
        numberOfAlbums: albumMap.values
            .where((songs) => songs.first.artist == artistName)
            .length,
        numberOfTracks: songsByArtist.length,
      );
      createdArtists[artistName] = artist;
    });
    _artists = createdArtists.values.toList();

    // Re-link songs to their album and artist objects
    _songs = _songs.map((song) {
      return song.copyWith(
        albumObj: createdAlbums[song.album],
        artistObj: createdArtists[song.artist],
      );
    }).toList();
  }

  void _loadPlaylists() {
    _playlists.clear();
    final box = Hive.box<String>('playlists');
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final id = data['id'] as String;
          final name = data['name'] as String;
          final createdAt = DateTime.fromMillisecondsSinceEpoch(
            data['createdAt'] as int,
          );
          final songIdsList = data['songIds'] as List<dynamic>;
          final songIdsSet = songIdsList.map((e) => e as int).toSet();

          final playlistSongs = _songs
              .where((s) => songIdsSet.contains(s.id))
              .toList();

          _playlists.add(
            Playlist(
              id: id,
              name: name,
              songs: playlistSongs,
              createdAt: createdAt,
            ),
          );
        } catch (e) {
          debugPrint('Failed to load playlist $key: $e');
        }
      }
    }
    _playlists.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  // Favorites management
  bool isFavorite(Song song) {
    return Hive.box<int>('favorites').containsKey(song.id);
  }

  Future<void> toggleFavorite(Song song) async {
    final box = Hive.box<int>('favorites');

    if (box.containsKey(song.id)) {
      await box.delete(song.id);
    } else {
      await box.put(song.id, DateTime.now().millisecondsSinceEpoch);
    }
    notifyListeners();
  }

  Future<void> _savePlaylist(Playlist p) async {
    final box = Hive.box<String>('playlists');
    final data = {
      'id': p.id,
      'name': p.name,
      'createdAt': p.createdAt.millisecondsSinceEpoch,
      'songIds': p.songs.map((s) => s.id).toList(),
    };
    await box.put(p.id, jsonEncode(data));
  }

  // Playlist management
  Future<void> createPlaylist(String name, List<Song> songs) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: songs,
      createdAt: DateTime.now(),
    );

    _playlists.add(playlist);
    _playlists.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    notifyListeners();
    await _savePlaylist(playlist);
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.songs.contains(song)) {
      playlist.songs.add(song);
      notifyListeners();
      await _savePlaylist(playlist);
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, Song song) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    playlist.songs.remove(song);
    notifyListeners();
    await _savePlaylist(playlist);
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
    final box = Hive.box<String>('playlists');
    await box.delete(playlistId);
  }

  // Search functionality
  List<Song> searchSongs(String query) {
    if (query.isEmpty) return _songs;

    return _songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(query.toLowerCase()) ||
              song.artist.toLowerCase().contains(query.toLowerCase()) ||
              song.album.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  List<Album> searchAlbums(String query) {
    if (query.isEmpty) return _albums;

    return _albums
        .where(
          (album) =>
              album.title.toLowerCase().contains(query.toLowerCase()) ||
              album.artist.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  List<Artist> searchArtists(String query) {
    if (query.isEmpty) return _artists;

    return _artists
        .where(
          (artist) => artist.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Get songs by album
  List<Song> getSongsByAlbum(String albumTitle) {
    return _songs.where((song) => song.album == albumTitle).toList();
  }

  // Get songs by artist
  List<Song> getSongsByArtist(String artistName) {
    return _songs.where((song) => song.artist == artistName).toList();
  }

  // Get albums by artist
  List<Album> getAlbumsByArtist(String artistName) {
    return _albums.where((album) => album.artist == artistName).toList();
  }
}
