import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nix/models/music/playlist.dart';
import 'package:nix/models/music/track.dart';
import 'package:nix/core/hive_keys.dart';

/// Manages Hive-backed storage and CRUD operations for user playlists.
class PlaylistRepository {
  /// Loads all playlists from the Hive box, matching saved track IDs with available library tracks.
  List<Playlist> loadPlaylists(List<Track> availableTracks) {
    final playlists = <Playlist>[];
    if (!Hive.isBoxOpen(HiveKeys.playlistsBox)) return playlists;

    final box = Hive.box<String>(HiveKeys.playlistsBox);
    final trackMap = {for (final t in availableTracks) t.id: t};

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
          final trackIdsList = data['trackIds'] as List<dynamic>;
          final trackIds = trackIdsList.map((e) => e as int).toList();

          final playlistTracks = trackIds
              .where((id) => trackMap.containsKey(id))
              .map((id) => trackMap[id]!)
              .toList();

          playlists.add(
            Playlist(
              id: id,
              name: name,
              tracks: playlistTracks,
              createdAt: createdAt,
            ),
          );
        } catch (e) {
          debugPrint('Failed to load playlist $key: $e');
        }
      }
    }

    playlists.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return playlists;
  }

  /// Persists a playlist model to the Hive storage box.
  Future<void> savePlaylist(Playlist playlist) async {
    final box = Hive.box<String>(HiveKeys.playlistsBox);
    final data = {
      'id': playlist.id,
      'name': playlist.name,
      'createdAt': playlist.createdAt.millisecondsSinceEpoch,
      'trackIds': playlist.tracks.map((s) => s.id).toList(),
    };
    await box.put(playlist.id, jsonEncode(data));
  }

  /// Deletes a playlist by ID from Hive.
  Future<void> deletePlaylist(String playlistId) async {
    if (!Hive.isBoxOpen(HiveKeys.playlistsBox)) return;
    final box = Hive.box<String>(HiveKeys.playlistsBox);
    await box.delete(playlistId);
  }

  /// Clears all stored playlists from Hive.
  Future<void> clearAll() async {
    if (Hive.isBoxOpen(HiveKeys.playlistsBox)) {
      await Hive.box<String>(HiveKeys.playlistsBox).clear();
    }
  }
}
