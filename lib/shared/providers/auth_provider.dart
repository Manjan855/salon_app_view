import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:salon_app_view/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _error;
  User? _user;

  bool get isAuthenticated => _authRepo.currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user ?? _supabase.auth.currentUser;

  // Helper getter to cleanly access the user's name from Supabase metadata
  String get userName =>
      user?.userMetadata?['fullName'] ??
      user?.userMetadata?['name'] ??
      'John Cena';

  // Clear any active error messages before performing an action
  void clearErrors() {
    _error = null;
    notifyListeners();
  }

  // Update Public Profile Table
  Future<bool> updateProfile({
    required String phone,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = _supabase.auth.currentUser ?? user;
      if (currentUser == null) throw Exception("No authenticated user found.");

      // 1. Check if a profile row already exists for this user ID
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      final profileData = {
        'id': currentUser.id,
        'name': name,
        'email': currentUser.email,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (response == null) {
        // 2. Row does not exist -> Perform a clean INSERT
        await _supabase.from('profiles').insert(profileData);
      } else {
        // 3. Row already exists -> Perform a target-specific UPDATE
        await _supabase
            .from('profiles')
            .update({
              'name': name,
              'phone': phone,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentUser.id);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = "An unexpected error occurred while saving information.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Handle Email/Password Login
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Send login request to Supabase
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user; // Cache the user locally

        // 2. CHECK IF PROFILE EXISTS: Smart navigation routing
        final profileCheck = await _supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        _isLoading = false;
        notifyListeners();

        if (profileCheck == null) {
          // Profile incomplete -> Go finish setting up details (phone number screen)
          return true;
        } else {
          // Profile complete -> We can tell the UI to jump straight home!
          return true;
        }
      }
      return false;
    } on AuthException catch (e) {
      _error = e.message; // Captures "Invalid login credentials", etc.
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = "An unexpected error occurred during login.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Handle Email/Password Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        // FIX: Explicitly cache the freshly registered user object locally
        _user = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = "An unexpected error occurred.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Define the mandatory Google permissions scopes
      final scopes = ['email', 'profile'];
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // 2. Initialize using the new 7.x package standard (serverClientId replaces webClientId)
      await googleSignIn.initialize(
        serverClientId:
            '940621050374-ilktvg4m4u01tgs390iru8fgquv2tc09.apps.googleusercontent.com',
      );

      // 3. Trigger the native account selector window
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false; // User cancelled the popup
      }

      // 4. Request explicit access tokens for the scopes we requested
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
          await googleUser.authorizationClient.authorizeScopes(scopes);

      final idToken = googleUser.authentication.idToken;
      final accessToken = authorization.accessToken;

      if (idToken == null || accessToken == null) {
        throw const AuthException(
          'Missing security tokens from Google Authentication.',
        );
      }

      // 5. Pass the clean tokens over to the Supabase session coordinator
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        _user = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      return false;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = "An unexpected error occurred during Google Sign-In.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Handle Logout
  Future<void> logoutUser() async {
    await _authRepo.signOut();
    notifyListeners();
  }
}
