// Mirrors GET /posts: { "userId": 1, "id": 1, "title": "...", "body": "..." }
// Post class
// Serialisation is the process of converting a Dart object into a format that can be easily stored or transmitted,
// such as JSON. Deserialization is the reverse process, where you convert data from a format like JSON back into a Dart object.
// In this Post class, we have implemented both serialization (toJson) and deserialization (fromJson) methods to facilitate
// easy conversion between Dart objects and JSON data when interacting with APIs.
// Created a Post class that can both read JSON from an API and convert itself back into JSON when sending data to an API.
//
// ── Media Module addition ──────────────────────────────────────────
// mediaType / mediaUrl are NEW, both nullable. They're populated only for
// posts created through the new Firebase-backed Upload Screen (Cloudinary
// for the file, Firestore for this metadata). Existing JSONPlaceholder
// posts simply never set them, and every read site (feed_post_card.dart)
// checks for null before trying to render media — so nothing about the
// old Browse/Detail/Create flow breaks.
//
// mediaType is a plain String rather than an enum so it round-trips
// through Firestore's Map<String, dynamic> documents without a custom
// converter — valid values are 'image', 'video', or 'audio'.
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String? mediaType; // 'image' | 'video' | 'audio' | null
  final String? mediaUrl;  // Cloudinary secure_url, or null

  //Constructor with required parameters

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.mediaType,
    this.mediaUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    //Implemented factory Post.fromJson() to convert API JSON into a Dart object.
    return Post(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      mediaType: json['mediaType'],
      mediaUrl: json['mediaUrl'],
    );
  }

  // Needed when POSTing a new post — http.post() expects a JSON-encodable body.
  Map<String, dynamic> toJson() {
    //Implemented toJson() to convert the Dart object back into JSON for POST requests.
    return {
      'userId': userId,
      'title': title,
      'body': body,
      if (mediaType != null) 'mediaType': mediaType,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    };
  }

  // ── Firestore-specific factory ──────────────────────────────────
  // Firestore documents need their own factory because the document id
  // (a String, e.g. "aB3xK9") lives separately from the document's field
  // data — unlike JSONPlaceholder, where `id` is just another int field
  // inside the same JSON body. We map Firestore's String doc id to this
  // Post's int `id` field using its hashCode, since the rest of the app
  // (favorites, drafts, feed gradients/categories) all key off an int id.
  factory Post.fromFirestore(String docId, Map<String, dynamic> data) {
    return Post(
      id: docId.hashCode,
      userId: data['userId'] ?? 0,
      title: data['caption'] ?? '',
      body: data['caption'] ?? '',
      mediaType: data['mediaType'],
      mediaUrl: data['mediaUrl'],
    );
  }
}