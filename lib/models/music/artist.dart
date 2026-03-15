class Artist {
  final int id;
  final String name;
  final int numberOfAlbums;
  final int numberOfTracks;

  Artist({
    required this.id,
    required this.name,
    required this.numberOfAlbums,
    required this.numberOfTracks,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Artist && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
