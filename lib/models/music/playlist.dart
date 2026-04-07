import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Song> songs;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description = '',
    required this.songs,
    required this.createdAt,
  });

  /// Total duration of all songs in milliseconds.
  int get totalDurationMs => songs.fold<int>(0, (sum, s) => sum + s.duration);

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<Song>? songs,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
