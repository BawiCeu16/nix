import 'track.dart';

class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Track> tracks;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description = '',
    required this.tracks,
    required this.createdAt,
  });

  /// Total duration of all tracks in milliseconds.
  int get totalDurationMs => tracks.fold<int>(0, (sum, s) => sum + s.duration);

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<Track>? tracks,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
