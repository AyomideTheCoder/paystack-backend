import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart'; // This must match the correct path

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()), // ✅ Login first
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/splash screen image.jpg', // Replace with your asset path for the pink sweater image
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Splash image load error: $error');
              return Container(
                color: const Color(0xFF10214B),
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                ),
              );
            },
          ),
          // Transparent Overlay
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF10214B).withOpacity(0.5), // 50% transparent overlay
            ),
          ),
          // Position logo at the bottom with a gap
          Positioned(
            bottom: 10, // Gap of 30 pixels from the bottom
            left: (MediaQuery.of(context).size.width - 300) / 2, // Center horizontally
            child: SizedBox(
              width: 300,
              height: 300,
              child: Image.asset(
                'assets/images/wearspace1_logo.png',
                width: 300,
                height: 300,
                color: Colors.white,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}