import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/core/router/route_name.dart';
import 'package:salon_app_view/shared/providers/auth_provider.dart';
import 'package:salon_app_view/shared/widgets/custom_button.dart';
import 'package:salon_app_view/shared/widgets/custom_text_field.dart' as shared;
import 'package:salon_app_view/features/auth/screens/register_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 1. Trigger the login action
      bool loginSuccess = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (loginSuccess) {
        // 2. Re-fetch profile status from the provider to determine destination
        final currentUser = Supabase.instance.client.auth.currentUser;

        // Check if this user already filled out their phone number in the profiles table
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', currentUser!.id)
            .maybeSingle();

        if (!mounted) return;

        if (profile == null || profile['phone'] == null) {
          // Missing phone info -> send them back to finish setting up
          Navigator.pushReplacementNamed(context, RouteName.persona);
        } else {
          // Everything exists -> Send them straight to the Home Screen!
          Navigator.pushReplacementNamed(context, RouteName.home);
        }
      } else {
        // Show the exact error message coming back from Supabase
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login Failed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Logo row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Image.asset("assets/hair2.png", width: 70, height: 70),

                      SvgPicture.asset(
                        "assets/hair.svg",
                        width: 70,
                        height: 70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Background illustration card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      "assets/first1.png",
                      height: screenHeight * 0.22,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Form Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(77),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "WELCOME BACK",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email Field
                        shared.CustomTextField(
                          controller: _emailController,
                          label: "Email",
                          hint: "Enter your email",
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Enter email";
                            }
                            if (!value.contains("@")) {
                              return "Enter valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        shared.CustomTextField(
                          controller: _passwordController,
                          label: "Password",
                          hint: "Enter your password",
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter Password";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login / Sign Up CTA
                        authProvider.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFC56AFF),
                                ),
                              )
                            : CustomButton(
                                text: "Login",
                                onPressed: _handleLogin,
                                height: 50,
                              ),
                        const SizedBox(height: 16),

                        // Google Sign In
                       // Locate the ElevatedButton.icon block inside your LoginScreen build method:
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: authProvider.isLoading
                              ? null
                              : () async {
                                  final success = await authProvider
                                      .loginWithGoogle();

                                  if (!mounted) return;

                                  if (success) {
                                    // If login is successful, route directly to the dashboard
                                    Navigator.pushReplacementNamed(
                                      context,
                                      RouteName.home,
                                    );
                                  } else if (authProvider.error != null) {
                                    // Display the concrete failure context returned from Supabase
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(authProvider.error!),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                          icon: Image.asset(
                            "assets/google2.png",
                            height: 22,
                            width: 22,
                          ),
                          label: const Text(
                            "Continue with Google",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Member Redirect
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Color(0xFFC56AFF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
