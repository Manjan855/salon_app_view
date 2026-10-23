import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/core/router/route_name.dart';
import 'package:salon_app_view/shared/providers/auth_provider.dart';
import 'package:salon_app_view/shared/widgets/custom_button.dart';
import 'package:salon_app_view/shared/widgets/custom_text_field.dart' as shared;

/// Shown after the user opens a Supabase password-reset link. The deep link has
/// already produced a short-lived recovery session, so saving here only needs a
/// new password (`auth.updateUser`).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final saved = await authProvider.updatePassword(_passwordController.text);

    if (!mounted) return;

    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated. You are signed in.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteName.home,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Could not update password.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _cancel() {
    // Drop recovery mode so the normal login flow takes over again.
    Provider.of<AuthProvider>(context, listen: false).clearPasswordRecovery();
    Navigator.pushNamedAndRemoveUntil(context, RouteName.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _cancel,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back to login',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'SET A NEW PASSWORD',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Choose a password with at least 6 characters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      shared.CustomTextField(
                        controller: _passwordController,
                        label: 'New password',
                        hint: 'Enter a new password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      shared.CustomTextField(
                        controller: _confirmController,
                        label: 'Confirm password',
                        hint: 'Re-enter the new password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      authProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFC56AFF),
                              ),
                            )
                          : CustomButton(
                              text: 'Save password',
                              onPressed: _save,
                              height: 50,
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
