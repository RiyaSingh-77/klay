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
  Future<void> fetchPostDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedPost = null;
    _comments = [];
    notifyListeners();
  // Provider asks ApiService:
  //Give me all posts. ApiService performs HTTP GET /posts
  //and returns a list of Post objects. 
  //Provider saves that list in _posts and calls notifyListeners() so the UI updates.
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