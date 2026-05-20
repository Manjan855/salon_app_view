import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Sign Up
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Create user model
      _user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: fullName,
        email: email,
        phone: phone,
        persona: '', // Will be set later
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Login
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock user for demo
      _user = UserModel(
        id: '123',
        fullName: 'John Doe',
        email: email,
        phone: '+1234567890',
        persona: 'customer',
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Update Persona
  Future<void> updatePersona(String persona) async {
    _setLoading(true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (_user != null) {
        _user = UserModel(
          id: _user!.id,
          fullName: _user!.fullName,
          email: _user!.email,
          phone: _user!.phone,
          persona: persona,
          profileImage: _user!.profileImage,
        );
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Save Location
  Future<void> saveLocation(String location) async {
    _setLoading(true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      // Save location to shared preferences or backend
      print('Location saved: $location');
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
