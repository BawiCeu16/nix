class Album {
  final int id;
  final String title;
  final String artist;
  final int numOfSongs;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.numOfSongs,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Album && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
