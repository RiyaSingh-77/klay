import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

// UserProvider drives the Explore Author step. Deliberately small and
// single-purpose — it only ever needs to hold ONE user at a time (whoever
// the user is currently viewing), unlike PostProvider which holds a whole
// list. Different shape of state, different provider — no reason to
// force everything into one giant provider.
class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _selectedUser;//Selects the currently viewed author.

  bool _isLoading = false; //controls the loading indicator
  String? _errorMessage;

  // ── All-users cache (Feed, Phase 7) ──────────────────────────
  // id -> User, built once from a single GET /users call. The feed reads
  // this synchronously for every post card's author name instead of
  // firing a network request per card. Separate from _selectedUser /
  // _isLoading above on purpose: loading the whole author list shouldn't
  // toggle the same spinner as loading ONE author's profile screen.
  Map<int, User> _usersById = {};
  bool _isLoadingUsers = false;

  //Getters
  User? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoadingUsers => _isLoadingUsers;

  Future<void> fetchUser(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedUser = null;
    notifyListeners();

    try {
      _selectedUser = await _apiService.fetchUser(userId);
    } catch (e) {
      _errorMessage = 'Could not load this author.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Call once when the feed loads. Safe to call again on pull-to-refresh
  // — it just re-fetches the same small list.
  Future<void> fetchAllUsers() async {
    _isLoadingUsers = true;
    notifyListeners();

    try {
      final users = await _apiService.fetchUsers();
      _usersById = {for (final u in users) u.id: u};
    } catch (e) {
      // Deliberately silent: a missing author name shouldn't block the
      // whole feed from rendering. authorName() below falls back cleanly.
    }

    _isLoadingUsers = false;
    notifyListeners();
  }

  // Synchronous, in-memory lookup — this is the whole point of caching
  // the list above. Falls back to a placeholder if the cache hasn't
  // loaded yet or that id genuinely doesn't exist.
  String authorName(int userId) => _usersById[userId]?.name ?? 'Unknown author';
}