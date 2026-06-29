import 'dart:convert';
import 'package:http/http.dart' as http;//This package allows Flutter to communicate with servers
import '../models/post.dart';//Because ApiService should never return raw JSON.
import '../models/user.dart';//All these model classes convert raw json into proper dart objects.
import '../models/album.dart';
import '../models/photo.dart';
import '../models/comment.dart';

// ApiService is the ONLY file in this project that imports `http` or knows
// the base URL. Every provider goes through these methods instead of
// calling http.get() directly — one place owns "how do we
// talk to the backend," everything else just calls methods and gets back
// typed Dart objects (Post, User, Album...), never raw JSON.
//ApiService is the application's networking layer. 
//Its responsibility is to hide all HTTP communication from the rest of the app. 
//It sends requests to the backend, converts JSON responses into strongly typed model objects (Post, User, Album, etc.),
// and returns those objects to Providers. This separation keeps UI, state management, and networking independent, making the code reusable, 
//testable, and easy to maintain.
class ApiService {//All networking in one place
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  // No call in this file is allowed to wait forever. Without a timeout,
  // a stalled connection (flaky Wi-Fi, VPN hiccup, campus network drop
  // http.get/post awaiting a response that may never arrive, which from
  // the UI's side looks exactly like a frozen loading spinner with no
  // error and no way to recover except restarting the app.
  static const Duration _timeout = Duration(seconds: 12);

  // ── Posts (Browse + Detail) ──────────────────────────────────
  Future<List<Post>> fetchPosts() async {
    final response = await http.get(Uri.parse('$_baseUrl/posts')).timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);//JSON String -> Dart List of dynamic objects (Map<String, dynamic>)
      return data.map((item) => Post.fromJson(item)).toList();//Dart List of dynamic objects -> Dart List of Post objects
    }
    throw Exception('Failed to load posts (status ${response.statusCode})');
  }

  Future<Post> fetchPost(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/posts/$id')).timeout(_timeout);
    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load post $id (status ${response.statusCode})');
  }

  Future<List<Comment>> fetchComments(int postId) async {
    final response = await http.get(Uri.parse('$_baseUrl/posts/$postId/comments')).timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Comment.fromJson(item)).toList();
    }
    throw Exception('Failed to load comments (status ${response.statusCode})');
  }//Server->List of JSON comments->Comment.fromJson()->List<Comment>

  //  Author (Explore Author) 
  Future<User> fetchUser(int userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/$userId')).timeout(_timeout);
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load user $userId (status ${response.statusCode})');
  }

  // The feed needs an author name on every post card, but JSONPlaceholder
  // only has 10 users total against 100 posts. Fetching /users/{id} once
  // PER CARD would mean up to 100 HTTP calls for one screen. Instead we
  // fetch the full /users list ONCE and let UserProvider build
  // an id -> User lookup map client-side, so every card after that is a
  // free in-memory read instead of a network call.
  Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/users')).timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => User.fromJson(item)).toList();
    }
    throw Exception('Failed to load users (status ${response.statusCode})');
  }

  // ── Albums + Photos (View Albums) ────────────────────────────
  // JSONPlaceholder supports nested-resource routes for "all albums
  // belonging to this user" — equivalent to /albums?userId={id}, but
  // reads more clearly as a relationship in the URL itself.
  Future<List<Album>> fetchAlbumsByUser(int userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/$userId/albums')).timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Album.fromJson(item)).toList();
    }
    throw Exception('Failed to load albums (status ${response.statusCode})');
  }

  Future<List<Photo>> fetchPhotosByAlbum(int albumId) async {
    final response = await http.get(Uri.parse('$_baseUrl/albums/$albumId/photos')).timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Photo.fromJson(item)).toList();
    }
    throw Exception('Failed to load photos (status ${response.statusCode})');
  }

  // ── Create Post ───────────────────────────────────────────────
  // IMPORTANT, same caveat as always with this mock API: this returns a
  // believable 201 Created with an id (e.g. 101), but nothing is actually
  // saved server-side. Fetching /posts/101 afterwards will 404. The
  // PostProvider compensates for this by inserting the returned
  // post into LOCAL state directly, rather than re-fetching the list.
  //
  // Note this only sends title/body/userId — the picked image and file
  // attachment from Create Post have no field on JSONPlaceholder's /posts
  // resource to be uploaded to. They're stored locally (as a Draft, or
  // alongside the post in local state) rather than sent over the network.
  // That's a deliberate, explainable boundary: the mock API defines what
  // CAN go over the wire, and the app's local persistence layer covers
  // the rest. Flutter->Server
  Future<Post> createPost({required String title, required String body, int userId = 1}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/posts'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'title': title, 'body': body, 'userId': userId}),
    ).timeout(_timeout);
    if (response.statusCode == 201) {
      return Post.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create post (status ${response.statusCode})');
  }
}