import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 100,
            children: [
              CircleAvatar(
                radius: 100,
                backgroundColor: Color(0xFFC56AFF),
                child: SvgPicture.asset(
                  "assets/logo.svg",
                  height: 100,
                  width: 100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
