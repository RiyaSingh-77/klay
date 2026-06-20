// GET /albums/{id}/photos:
// { "albumId": 1, "id": 1, "title": "...", "url": "...", "thumbnailUrl": "..." }
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