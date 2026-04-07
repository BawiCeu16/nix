class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String uri;
  final int duration;
  final int size;
  final int dateAdded;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.uri,
    required this.duration,
    this.size = 0,
    required this.dateAdded,
  });

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? uri,
    int? duration,
    int? size,
    int? dateAdded,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      uri: uri ?? this.uri,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Song && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
