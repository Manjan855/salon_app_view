import 'package:flutter/material.dart';
import 'package:salon_app_view/core/router/route_name.dart';
import 'package:salon_app_view/shared/widgets/custom_button.dart';
import 'package:salon_app_view/shared/widgets/custom_text_field.dart' as shared;
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonaScreen extends StatefulWidget {
  const PersonaScreen({super.key});

  @override
  State<PersonaScreen> createState() => _PersonaScreenState();
}

class _PersonaScreenState extends State<PersonaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Pre-fill full name from metadata if available (e.g., from Google auth)
      final name =
          user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
      if (name != null) {
        _fullNameController.text = name;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Upsert profile data into Supabase 'profiles' table
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // Profile complete — navigate to Home
      Navigator.pushReplacementNamed(context, RouteName.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving profile: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    "Complete Your Profile",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "We need your phone number to confirm salon appointment bookings.",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // Container Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        // Full Name
                        shared.CustomTextField(
                          controller: _fullNameController,
                          label: "Full Name",
                          hint: "Enter your full name",
                          prefixIcon: Icons.person_outline,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Please enter your name";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // // Phone Number
                        // shared.CustomTextField(
                        //   controller: _phoneController,
                        //   label: "Phone Number",
                        //   hint: "Enter 10-digit phone number",
                        //   prefixIcon: Icons.phone_outlined,
                        //   keyboardType: TextInputType.phone,
                        //   validator: (val) {
                        //     if (val == null || val.trim().isEmpty) {
                        //       return "Phone number is required";
                        //     }
                        //     if (val.trim().length < 8) {
                        //       return "Enter a valid phone number";
                        //     }
                        //     return null;
                        //   },
                        // ),
                        const SizedBox(height: 28),

                        // Save Button
                        _isSaving
                            ? const CircularProgressIndicator(
                                color: Color(0xFFC56AFF),
                              )
                            : CustomButton(
                                text: "Continue to App",
                                onPressed: _saveProfile,
                                height: 50,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
