import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('About Us', style: TextStyle(color: Colors.white70)),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Our App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to our platform! We are dedicated to providing a seamless experience for buying and selling products. Our mission is to connect people through a user-friendly marketplace, offering a wide range of items with ease and convenience.',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Our Vision',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'To create a trusted and innovative platform that empowers users to discover, buy, and sell products effortlessly.',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Contact Us',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Have questions? Reach out to us at support@example.com or visit our Contact Us page.',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}