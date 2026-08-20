import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get the currently logged-in user
  User? get currentUser => _supabase.auth.currentUser;

  // Stream to watch if the user logs in or out in real-time
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // 1. Sign Up with Email and Password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Sign Up Failed: $e');
    }
  }

  // 2. Login with Email and Password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  // 3. Sign Out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign Out Failed: $e');
    }
  }
}
