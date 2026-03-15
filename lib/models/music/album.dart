import 'images.dart';

class Album {
  final int id;
  final String title;
  final String artist;
  final int numOfSongs;
  final Images? images;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.numOfSongs,
    this.images,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Album && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
