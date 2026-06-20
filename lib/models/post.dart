// Mirrors GET /posts: { "userId": 1, "id": 1, "title": "...", "body": "..." }
//Post class
//Serialisation is the process of converting a Dart object into a format that can be easily stored or transmitted,
// such as JSON. Deserialization is the reverse process, where you convert data from a format like JSON back into a Dart object.
// In this Post class, we have implemented both serialization (toJson) and deserialization (fromJson) methods to facilitate
// easy conversion between Dart objects and JSON data when interacting with APIs.
// Created a Post class that can both read JSON from an API and convert itself back into JSON when sending data to an API.
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