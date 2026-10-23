import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:salon_app_view/app_env.dart';
import 'package:salon_app_view/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _error;
  User? _user;

  /// True after the user opens a password-reset link. The splash/root listener
  /// uses it to route to the "set a new password" screen instead of home.
  bool _isPasswordRecovery = false;
  StreamSubscription<AuthState>? _authSubscription;

  /// Persisted when a reset email is sent. If the app is killed and relaunched
  /// by the link, the `passwordRecovery` event can fire before this provider
  /// subscribes, so this marker lets the splash screen recover the state.
  static const String pendingResetKey = 'pendingPasswordReset';

  AuthProvider() {
    // Supabase's deep-link observer exchanges the recovery `code` and emits
    // `passwordRecovery` (see gotrue exchangeCodeForSession). Capture it here so
    // the UI can react no matter which screen is on top.
    _authSubscription = _supabase.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
        _error = null;
        notifyListeners();
      } else if (state.event == AuthChangeEvent.signedIn &&
          _isPasswordRecovery) {
        // A normal sign-in supersedes a stale recovery request.
        _isPasswordRecovery = false;
        _clearPendingResetPref();
        notifyListeners();
      }
    });
  }

  bool get isAuthenticated => _authRepo.currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPasswordRecovery => _isPasswordRecovery;
  User? get user => _user ?? _supabase.auth.currentUser;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Leaves recovery mode once the new password is saved (or the user backs out).
  void clearPasswordRecovery() {
    if (!_isPasswordRecovery) return;
    _isPasswordRecovery = false;
    _clearPendingResetPref();
    notifyListeners();
  }

  /// Cold-start fallback: if a reset was requested and a session now exists but
  /// the `passwordRecovery` event was missed, restore recovery mode.
  Future<void> restorePendingPasswordReset() async {
    if (_isPasswordRecovery) return;
    if (_supabase.auth.currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(pendingResetKey) != true) return;

    _isPasswordRecovery = true;
    notifyListeners();
  }

  Future<void> _clearPendingResetPref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pendingResetKey);
  }

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
  Future<bool> login( {required String email, required String password}) async {
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

  /// Sends a Supabase password-reset email. The link returns to the app via
  /// [AppEnv.authRedirectUrl]; opening it emits [AuthChangeEvent.passwordRecovery]
  /// and routes the user to the "set new password" screen.
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppEnv.authRedirectUrl,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(pendingResetKey, true);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Could not send the reset email. Check your connection and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Saves a new password for the user currently in a recovery session.
  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      _isPasswordRecovery = false;
      await _clearPendingResetPref();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Could not update your password. Please try again.';
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
        // If "Confirm email" is ever switched on, the confirmation link
        // returns here instead of the project Site URL — with PKCE the
        // ?code= lands in the app and is exchanged for the session.
        // (The project currently has mailer_autoconfirm enabled, so no
        // link is sent today; this is the ready-when-you-are wiring.)
        emailRedirectTo: AppEnv.authRedirectUrl,
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

      // 2. Initialize using the google_sign_in 7.x API. The web/server client
      //    ID is injected at build time (config/supabase.json -> AppEnv), never
      //    hardcoded in source. See docs/google_signin.md.
      if (!AppEnv.hasGoogleServerClientId) {
        throw const AuthException(
          'Google Sign-In is not configured on this build '
          '(GOOGLE_SERVER_CLIENT_ID is missing).',
        );
      }
      await googleSignIn.initialize(
        serverClientId: AppEnv.googleServerClientId,
      );

      // 3. Trigger the native account selector window
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // 4. Request an OAuth access token for the scopes we asked for. This is
      //    best-effort: Supabase verifies the ID token, so a scope-grant
      //    failure must not sink an otherwise successful sign-in.
      String? accessToken;
      try {
        final authorization = await googleUser.authorizationClient
                .authorizationForScopes(scopes) ??
            await googleUser.authorizationClient.authorizeScopes(scopes);
        accessToken = authorization.accessToken;
      } catch (_) {
        accessToken = null;
      }

      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
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

      _user = response.user ?? _user;
      _isLoading = false;
      notifyListeners();
      return response.user != null;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } on GoogleSignInException catch (e) {
      _error = _describeGoogleSignInError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Google Sign-In failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Maps an opaque [GoogleSignInException] onto an actionable message. The
  /// `clientConfigurationError` case almost always means the Android package
  /// name + SHA-1 (or the iOS bundle id) is not registered in Google Cloud
  /// Console — see docs/google_signin.md.
  static String _describeGoogleSignInError(GoogleSignInException e) {
    final detail = e.description == null ? '' : '\n${e.description}';
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google Sign-In was cancelled.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google Sign-In is misconfigured for this app: the Android '
            'package name + SHA-1 (or iOS bundle id) are not registered in '
            'Google Cloud Console. See docs/google_signin.md.$detail';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google provider is misconfigured. '
            'See docs/google_signin.md.$detail';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Please sign in with the same Google account again.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google Sign-In was interrupted. Please try again.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Could not show the Google Sign-In window. Please try again.';
      default:
        return 'Google Sign-In failed: ${e.description ?? e.code.name}';
    }
  }

  // Handle Logout
  Future<void> logoutUser() async {
    await _authRepo.signOut();
    notifyListeners();
  }
}
