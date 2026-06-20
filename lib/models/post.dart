// Mirrors GET /posts: { "userId": 1, "id": 1, "title": "...", "body": "..." }
//Post class
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  //Constructor with required parameters


  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {//Implemented factory Post.fromJson() to convert API JSON into a Dart object.
    return Post(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
    );
  }

  // Needed when POSTing a new post — http.post() expects a JSON-encodable body.
  Map<String, dynamic> toJson() {//Implemented toJson() to convert the Dart object back into JSON for POST requests.
    return {'userId': userId, 'title': title, 'body': body};
  }
}