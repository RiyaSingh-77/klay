import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

// FirestoreService is the ONLY file in this project that imports
// cloud_firestore or knows the collection name — same separation-of-
// concerns rule as ApiService for JSONPlaceholder and CloudinaryService
// for media uploads. PostProvider calls these methods and gets back
// typed Post objects, never a raw DocumentSnapshot or QuerySnapshot.
//
// Collection shape (per post document):
//   postId      (String)    — same as the document's own id, stored
//                              redundantly so it's also readable inside
//                              the document data itself, not just as
//                              metadata on the snapshot
//   userId      (int)
//   caption     (String)
//   mediaType   (String)    — 'image' | 'video' | 'audio'
//   mediaUrl    (String)    — Cloudinary secure_url
//   createdAt   (Timestamp) — set via FieldValue.serverTimestamp(), so
//                              ordering is correct even if the device's
//                              local clock is wrong
//   likes       (int)
//   comments    (int)
class FirestoreService {
  static const String _collectionName = 'posts';

  final CollectionReference<Map<String, dynamic>> _postsRef =
      FirebaseFirestore.instance.collection(_collectionName);

  // ── Create ────────────────────────────────────────────────────
  // Called AFTER CloudinaryService.uploadMedia() succeeds — this method
  // never touches the file itself, only the metadata that points at it.
  // Returns the created Post (with its real Firestore doc id folded in
  // via Post.fromFirestore) so the Upload Screen can navigate back
  // immediately with the new post ready to show, instead of waiting on
  // a separate re-fetch.
  Future<Post> createPost({
    required int userId,
    required String caption,
    required String mediaType,
    required String mediaUrl,
  }) async {
    final docRef = _postsRef.doc(); // generates the id client-side, upfront
    final data = {
      'postId': docRef.id,
      'userId': userId,
      'caption': caption,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
    };
    await docRef.set(data);

    // serverTimestamp() only resolves to a real value once it reaches
    // the server — reading it back immediately here would show null.
    // That's fine: this Post is about to be inserted at the TOP of the
    // feed's local list regardless, so its exact createdAt value isn't
    // needed for sorting yet. Post.fromFirestore handles a missing/null
    // createdAt gracefully (see model).
    return Post.fromFirestore(docRef.id, data);
  }

  // ── Read (one-time) ──────────────────────────────────────────────
  // Ordered newest-first. Used for an initial load before the live
  // stream below takes over, or anywhere a one-shot fetch is simpler
  // than subscribing to a stream (e.g. pull-to-refresh).
  Future<List<Post>> fetchPosts() async {
    final snapshot = await _postsRef
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Post.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  // ── Read (live stream) ────────────────────────────────────────────
  // Firestore pushes updates automatically — no manual refresh needed
  // for the feed to show a new post the instant it's created, even from
  // a different device. PostProvider listens to this and calls
  // notifyListeners() on every event.
  Stream<List<Post>> watchPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  // ── Delete ────────────────────────────────────────────────────────
  // Not part of the original six-step flow, but included since the
  // Upload Screen's error-handling path may need to roll back a
  // half-created post if something fails after the document write but
  // before the screen confirms success to the user.
  Future<void> deletePost(String postId) async {
    await _postsRef.doc(postId).delete();
  }
}