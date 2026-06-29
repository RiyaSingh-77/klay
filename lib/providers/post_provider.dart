import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

// PostProvider drives three of the flow's six steps: Browse Posts,
// View Details, and Create Post. Screens call its methods and watch its
// getters — they never touch ApiService, FirestoreService, or
// CloudinaryService directly.
//
// ── Media Module addition ──────────────────────────────────────────
// Two parallel post sources now feed this provider: JSONPlaceholder
// (_posts, exactly as before) and Firestore (_mediaPosts, NEW). The
// combined `posts` getter merges them, media posts first, so the Feed
// shows real uploads at the top without needing to know two sources
// exist at all — it just reads PostProvider.posts like it always did.
class PostProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  List<Post> _posts = [];
  List<Post> _mediaPosts = []; // live, Firestore-backed
  Post? _selectedPost;
  List<Comment> _comments = [];

  bool _isLoading = false;
  String? _errorMessage;

  // ── Media upload state ───────────────────────────────────────────
  bool _isUploadingMedia = false;
  double _uploadProgress = 0.0;
  String? _uploadErrorMessage;

  StreamSubscription<List<Post>>? _mediaSubscription;

  // Combined list — media posts (newest Firestore writes) shown first,
  // then the JSONPlaceholder posts that originally seeded the feed.
  List<Post> get posts => [..._mediaPosts, ..._posts];
  Post? get selectedPost => _selectedPost;
  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isUploadingMedia => _isUploadingMedia;
  double get uploadProgress => _uploadProgress;
  String? get uploadErrorMessage => _uploadErrorMessage;

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

  // ── Live Media Feed (Firestore) ──────────────────────────────────
  // Call once, early — e.g. from FeedScreen.initState() — alongside
  // fetchPosts(). Firestore pushes every new/changed post automatically,
  // so the feed updates the instant an upload finishes, with no manual
  // refresh and no polling.
  void startWatchingMediaPosts() {
    _mediaSubscription?.cancel(); // avoid double subscriptions if called twice
    _mediaSubscription = _firestoreService.watchPosts().listen(
      (posts) {
        _mediaPosts = posts;
        notifyListeners();
      },
      onError: (e) {
        // A live-stream failure (e.g. permissions, offline) shouldn't
        // wipe out posts already loaded — just stop updating silently.
        // The JSONPlaceholder side of the feed keeps working either way.
      },
    );
  }

  @override
  void dispose() {
    _mediaSubscription?.cancel();
    super.dispose();
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
  //
  // Media posts (Firestore-backed) are ALWAYS purely local-list lookups
  // — there is no equivalent "fetch a single Firestore post by this int
  // id" path, since the int id is a hashCode of the real Firestore doc
  // id, not something Firestore itself can query by. So those posts
  // must already be in _mediaPosts (from the live stream) to be found.
  Future<void> fetchPostDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedPost = null;
    _comments = [];
    notifyListeners();

    final localMatch = posts.where((p) => p.id == id).toList();
    if (localMatch.isNotEmpty) {
      _selectedPost = localMatch.first;
      // Comments are still worth trying over the network even for a
      // locally-created or media post — JSONPlaceholder's nested
      // /comments route returns an empty list (not a 404) for an
      // unknown parent id, so this just resolves to "no comments yet"
      // rather than erroring.
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

  // ── Create Post (JSONPlaceholder — unchanged) ────────────────────
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

  // ── Create Media Post (Cloudinary + Firestore) ───────────────────
  // Orchestrates the full upload: Cloudinary first (so we have a real
  // URL), then Firestore (so the URL is saved as metadata). If
  // Cloudinary succeeds but Firestore fails, we deliberately do NOT try
  // to delete the Cloudinary asset — an orphaned file costs nothing
  // (well within free tier) and is far safer than silently losing a
  // post the user thinks succeeded. Returns true on full success.
  //
  // _mediaPosts updates on its own via the live stream once Firestore's
  // write lands — this method does NOT manually insert into any local
  // list, unlike createPost() above. That's intentional: it avoids a
  // brief duplicate flash (one from this method, one from the stream
  // catching up a moment later).
  Future<bool> uploadMediaPost({
    required Uint8List bytes,
    required String fileName,
    required String mediaType, // 'image' | 'video' | 'audio'
    required String caption,
    int userId = 1,
  }) async {
    _isUploadingMedia = true;
    _uploadProgress = 0.0;
    _uploadErrorMessage = null;
    notifyListeners();

    try {
      final mediaUrl = await _cloudinaryService.uploadMedia(
        bytes: bytes,
        fileName: fileName,
        mediaType: mediaType,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      await _firestoreService.createPost(
        userId: userId,
        caption: caption,
        mediaType: mediaType,
        mediaUrl: mediaUrl,
      );

      _isUploadingMedia = false;
      _uploadProgress = 1.0;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploadingMedia = false;
      _uploadErrorMessage = 'Upload failed: $e';
      notifyListeners();
      return false;
    }
  }
}