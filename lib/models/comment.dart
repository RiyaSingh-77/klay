// GET /posts/{id}/comments:
// { "postId": 1, "id": 1, "name": "...", "email": "...", "body": "..." }
//Define the structure of a Comment. Convert JSON into a Dart object.
class Comment {
  final int id;
  final int postId;
  final String name;
  final String email;
  final String body;

  Comment({
    required this.id,
    required this.postId,
    required this.name,
    required this.email,
    required this.body,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      postId: json['postId'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      body: json['body'] ?? '',
    );
  }
}