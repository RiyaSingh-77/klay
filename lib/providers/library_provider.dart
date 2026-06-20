import 'package:flutter/material.dart';
import '../models/draft.dart';
import '../services/storage_service.dart';

// LibraryProvider holds in-memory state for favorites + drafts, and keeps
// it in sync with StorageService on every change. The pattern: mutate the
// in-memory list, call notifyListeners() so the UI updates instantly
// (feels responsive), THEN persist to SharedPreferences in the
// background. The UI never waits on disk I/O to feel like it worked.
class LibraryProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
//Private variables
  List<int> _favoriteIds = [];
  List<Draft> _drafts = [];
  bool _isLoaded = false;

  //Getters for the private fields, so other parts(UI) of the app can safely read them but not modify them directly.

  List<int> get favoriteIds => _favoriteIds;
  List<Draft> get drafts => _drafts;
  bool get isLoaded => _isLoaded;

  bool isFavorite(int postId) => _favoriteIds.contains(postId);

  // Call once, early (e.g. from a splash screen or app startup), to load
  // whatever was saved last session before the user touches anything.
  Future<void> loadLibrary() async {
    _favoriteIds = await _storageService.getFavoriteIds();//Load the list of favorite post IDs from local storage
    _drafts = await _storageService.getDrafts();
    _isLoaded = true;//Loading complete
    notifyListeners();
  }

  // ── Favorites ─────────────────────────────────────────────────
  // Single toggle method instead of separate add/remove — the UI (a heart
  // icon) only ever needs "flip the current state," not two methods to
  // choose between.
  Future<void> toggleFavorite(int postId) async {
    if (_favoriteIds.contains(postId)) {
      _favoriteIds.remove(postId);
    } else {
      _favoriteIds.add(postId);
    }
    notifyListeners(); // update UI immediately
    await _storageService.saveFavoriteIds(_favoriteIds); // persist after
  }

  // ── Drafts ────────────────────────────────────────────────────
  Future<void> saveDraft(Draft draft) async {
    // If a draft with this id already exists, replace it (editing an
    // existing draft) — otherwise add as new.
    final index = _drafts.indexWhere((d) => d.id == draft.id);
    if (index != -1) {
      _drafts[index] = draft;
    } else {
      _drafts.insert(0, draft);
    }
    notifyListeners();
    await _storageService.saveDrafts(_drafts);
  }

  Future<void> deleteDraft(String draftId) async {
    _drafts.removeWhere((d) => d.id == draftId);
    notifyListeners();
    await _storageService.saveDrafts(_drafts);
  }
}