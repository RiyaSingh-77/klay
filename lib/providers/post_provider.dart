import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/api_service.dart';

// PostProvider drives three of the flow's six steps: Browse Posts,
// View Details, and Create Post. Screens call its methods and watch its
// getters — they never touch ApiService directly.
class PostProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();//Creates an instance of ApiService which is responsible for making HTTP requests.


  List<Post> _posts = [];
  Post? _selectedPost;
  List<Comment> _comments = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Post> get posts => _posts;
  Post? get selectedPost => _selectedPost;
  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Browse Posts ──────────────────────────────────────────────
  Future<void> fetchPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _apiService.fetchPosts();
    } catch (e) {
      _errorMessage = 'Could not load posts. Check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── View Details ──────────────────────────────────────────────
  // Fetches the post AND its comments together, so the detail screen has
  // one loading state to handle instead of juggling two spinners.
  //
  // IMPORTANT: a post created via createPost() below only ever exists in
  // THIS app's local _posts list — JSONPlaceholder's mock /posts never
  // actually saves it (see ApiService.createPost's comment). So a plain
  // GET /posts/{id} for a freshly-created post's id 404s every time,
  // even though it's sitting right there in _posts. We check the local
  // list FIRST and only hit the network if it's genuinely not there.
  Future<void> fetchPostDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedPost = null;
    _comments = [];
    notifyListeners();

    final localMatch = _posts.where((p) => p.id == id).toList();
    if (localMatch.isNotEmpty) {
      _selectedPost = localMatch.first;
      // Comments are still worth trying over the network even for a
      // locally-created post — JSONPlaceholder's nested /comments route
      // returns an empty list (not a 404) for an unknown parent id, so
      // this just resolves to "no comments yet" rather than erroring.
      try {
        _comments = await _apiService.fetchComments(id);
      } catch (e) {
        _comments = [];
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _selectedPost = await _apiService.fetchPost(id);
      _comments = await _apiService.fetchComments(id);
    } catch (e) {
      _errorMessage = 'Could not load this post.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Create Post ───────────────────────────────────────────────
  // Returns the created Post (or null on failure) rather than just a
  // bool — the create-post screen needs the new post's id to build a
  // Draft/local record alongside it (image + attachment paths), since
  // JSONPlaceholder's response only ever contains title/body/userId/id.
  Future<Post?> createPost({required String title, required String body}) async {
    _errorMessage = null;
    try {
      final newPost = await _apiService.createPost(title: title, body: body);
      // Inserted into local state directly — re-fetching the list from
      // the server wouldn't show it, since JSONPlaceholder doesn't
      // actually persist new posts (see ApiService.createPost).
      _posts.insert(0, newPost);
      notifyListeners();
      return newPost;
    } catch (e) {
      _errorMessage = 'Could not create post.';
      notifyListeners();
      return null;
    }
  }
}