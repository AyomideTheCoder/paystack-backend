import 'package:flutter/material.dart';

class UpdateNoticePage extends StatelessWidget {
  const UpdateNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Update Notice', style: TextStyle(color: Colors.white70)),
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
              'Latest Updates',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Version 1.2.0 - July 31, 2025',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '- Improved image picker stability for macOS and mobile platforms.\n'
              '- Added About Us and Update Notice pages to the sidebar menu.\n'
              '- Enhanced form validation for product listings.\n'
              '- Bug fixes and performance improvements.',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Stay Updated',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check this page regularly for the latest updates and new features. Enable notifications in Settings to stay informed!',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}