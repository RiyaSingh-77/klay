// GET /albums/{id}/photos:
// { "albumId": 1, "id": 1, "title": "...", "url": "...", "thumbnailUrl": "..." }
//The Photo model represents a single image returned by the API.
// It converts raw JSON into a strongly typed Dart object using fromJson(). 
//Each Photo belongs to an Album (albumId), illustrating a one-to-many relationship.
// The model separates API data from UI logic, making the code cleaner, type-safe, and easier to maintain.
class Photo {
  final int id;
  final int albumId;
  final String title;
  final String url;
  final String thumbnailUrl;

  Photo({
    required this.id,
    required this.albumId,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] ?? 0,
      albumId: json['albumId'] ?? 0,
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
    );
  }
}