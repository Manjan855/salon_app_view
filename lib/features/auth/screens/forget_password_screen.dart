import 'package:flutter/material.dart';
import 'package:salon_app_view/features/auth/screens/personal_info.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Stack(
        children: [
          Positioned(
            top: 100,
            left: 14,
            right: 14,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: MediaQuery.sizeOf(context).height * 0.6,
                width: double.infinity,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text("Forget Password Page"),
                    const SizedBox(height: 24),
                    const CustomButton(title: 'Enter you Gmail'),
                    const SizedBox(height: 15),
                    const CustomButton(title: 'Enter your password'),
                    const SizedBox(height: 15),
                    const CustomButton(title: 'Renter your Password'),
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
