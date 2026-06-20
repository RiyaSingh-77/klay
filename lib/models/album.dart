// GET /users/{id}/albums: { "userId": 1, "id": 1, "title": "..." }
//Every API entity gets its own model class.
//Instead of passing raw JSON throughout the app, we can use model classes to represent the data in a structured way. 
//This makes it easier to work with the data and provides type safety.
class Album {
  final int id;
  final int userId;
  final String title;

  Album({required this.id, required this.userId, required this.title});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] ?? 0, //?? null-coalescing operator.
      userId: json['userId'] ?? 0,
      title: json['title'] ?? '',
    );
  }
}