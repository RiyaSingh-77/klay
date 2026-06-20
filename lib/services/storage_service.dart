import 'dart:convert';//Draft objects must be converted into strings before saving.
import 'package:shared_preferences/shared_preferences.dart';
import '../models/draft.dart'; //because StorageService stores and retrieves Draft objects.


// StorageService is to local persistence what ApiService is to the
// network: the ONLY file that imports shared_preferences or knows the
// storage keys. LibraryProvider calls these methods, never
// SharedPreferences directly — same separation-of-concerns rule used
// everywhere else in this app.
//
// Why SharedPreferences instead of a real database (e.g. sqflite)?
// Favorites and drafts here are small, simple data (a list of IDs, a
// handful of draft posts) — SharedPreferences is key-value storage,
// good enough for this scale, and far less setup than a SQL database.
//Why not database?
// If this app needed complex queries or large datasets, that'd be the
// signal to move to sqflite or Hive.
class StorageService {
  static const String _favoritesKey = 'favorite_post_ids';
  static const String _draftsKey = 'drafts';

  // ── Favorites ─────────────────────────────────────────────────
  // Stored as a List<String> because SharedPreferences cannot store
  // List<int> type — we convert int -> String going in, String -> int
  // coming out.
  Future<List<int>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();//Open LocalStorage
    final stored = prefs.getStringList(_favoritesKey) ?? [];
    return stored.map((id) => int.parse(id)).toList();
  }

  Future<void> saveFavoriteIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, ids.map((id) => id.toString()).toList());
  }

  // ── Drafts ────────────────────────────────────────────────────
  // Each Draft is jsonEncode()'d into its own String; the whole list of
  // drafts is stored as a List<String> of those JSON strings. This is
  // the standard pattern for storing a list of objects in
  // SharedPreferences, since it can only natively hold a List<String>.
  Future<List<Draft>> getDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_draftsKey) ?? [];
    return stored
        .map((jsonString) => Draft.fromJson(jsonDecode(jsonString)))
        .toList();
  }

  Future<void> saveDrafts(List<Draft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = drafts.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_draftsKey, encoded);
  }
}