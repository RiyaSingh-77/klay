import 'package:flutter/material.dart';
import '../models/album.dart';
import '../models/photo.dart';
import '../services/api_service.dart';

// AlbumProvider drives the View Albums step, which has two levels:
// 1. A user's list of albums (fetchAlbumsByUser)
// 2. The photos inside one selected album (fetchPhotosByAlbum)
//
// Both levels share one provider rather than splitting into
// AlbumListProvider/AlbumPhotosProvider — they're tightly related (you
// can't view photos without first picking an album) and the screens that
// use them sit right next to each other in the navigation flow.
class AlbumProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Album> _albums = [];
  List<Photo> _photos = [];

  bool _isLoadingAlbums = false;
  bool _isLoadingPhotos = false;
  String? _errorMessage;

  List<Album> get albums => _albums;
  List<Photo> get photos => _photos;
  bool get isLoadingAlbums => _isLoadingAlbums;
  bool get isLoadingPhotos => _isLoadingPhotos;
  String? get errorMessage => _errorMessage;

  // ── Level 1: albums belonging to an author ───────────────────
  Future<void> fetchAlbumsByUser(int userId) async {
    _isLoadingAlbums = true;
    _errorMessage = null;
    _albums = [];
    notifyListeners();

    try {
      _albums = await _apiService.fetchAlbumsByUser(userId);
    } catch (e) {
      _errorMessage = 'Could not load albums.';
    }

    _isLoadingAlbums = false;
    notifyListeners();
  }

  // ── Level 2: photos inside one album ─────────────────────────
  // Separate loading flag from albums (_isLoadingPhotos vs
  // _isLoadingAlbums) — tapping into an album shouldn't show the whole
  // album grid as loading again, only the photo grid that's actually
  // being fetched.
  Future<void> fetchPhotosByAlbum(int albumId) async {
    _isLoadingPhotos = true;
    _errorMessage = null;
    _photos = [];
    notifyListeners();

    try {
      _photos = await _apiService.fetchPhotosByAlbum(albumId);
    } catch (e) {
      _errorMessage = 'Could not load photos.';
    }

    _isLoadingPhotos = false;
    notifyListeners();
  }
}