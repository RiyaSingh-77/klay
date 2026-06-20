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
  //Getters
  User? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
}