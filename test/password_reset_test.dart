// Guards the password-reset wiring without touching the network:
//   login screen -> AuthProvider.sendPasswordResetEmail -> AppEnv.authRedirectUrl
//   deep link   -> AuthChangeEvent.passwordRecovery -> ResetPasswordScreen
//   screen      -> AuthProvider.updatePassword -> auth.updateUser
//
// Run with:
//   flutter test test/password_reset_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/app_env.dart';
import 'package:salon_app_view/core/router/route_name.dart';

void main() {
  final provider = File('lib/shared/providers/auth_provider.dart')
      .readAsStringSync();
  final runApp = File('lib/run_app.dart').readAsStringSync();
  final login = File('lib/features/auth/screens/login_screen.dart')
      .readAsStringSync();
  final splash =
      File('lib/features/onboarding/screens/splash_screen.dart').readAsStringSync();

  test('reset route is defined and registered', () {
    expect(RouteName.resetPassword, '/reset-password');
    expect(runApp, contains('RouteName.resetPassword:'),
        reason: 'MaterialApp.routes must include the reset screen');
    expect(runApp, contains('ResetPasswordScreen'),
        reason: 'the reset screen must be importable from run_app.dart');
  });

  test('reset email uses the declared deep link', () {
    expect(provider, contains('resetPasswordForEmail'),
        reason: 'password reset must go through Supabase');
    expect(provider, contains('redirectTo: AppEnv.authRedirectUrl'),
        reason: 'the email link must return to the app, not the browser');
  });

  test('recovery event routes to the reset screen', () {
    expect(provider, contains('AuthChangeEvent.passwordRecovery'),
        reason: 'Supabase emits this when the reset link is opened');
    expect(provider, contains('isPasswordRecovery'),
        reason: 'the UI needs a flag to know a recovery session is active');
    expect(runApp, contains('_PasswordRecoveryHandler'),
        reason: 'a root listener must push the reset screen on recovery');
    expect(splash, contains('isPasswordRecovery'),
        reason: 'a cold-start recovery must not be redirected to home');
  });

  test('cold start recovers a missed recovery event', () {
    expect(provider, contains('pendingPasswordReset'),
        reason: 'the reset request must survive process death');
    expect(provider, contains('restorePendingPasswordReset'),
        reason: 'a missed event must be recoverable from the marker');
    expect(splash, contains('restorePendingPasswordReset'),
        reason: 'the splash screen is the cold-start entry point');
  });

  test('new password is saved with updateUser', () {
    expect(provider, contains('updateUser(UserAttributes(password:'),
        reason: 'setting a new password is auth.updateUser');
  });

  test('login screen exposes the entry point', () {
    expect(login, contains('Forgot Password?'));
    expect(login, contains('sendPasswordResetEmail'));
  });

  test('auth redirect scheme is non-empty', () {
    final uri = Uri.parse(AppEnv.authRedirectUrl);
    expect(uri.scheme, isNotEmpty);
    expect(uri.host, isNotEmpty);
  });
}
