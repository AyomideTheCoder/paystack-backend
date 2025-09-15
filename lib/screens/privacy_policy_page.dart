import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  _PrivacyPolicyPageState createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  // Track expanded state of sections
  final Map<String, bool> _expandedSections = {
    'introduction': false,
    'dataCollection': false,
    'dataUsage': false,
    'userRights': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10214B),
      body: SafeArea(
        child: Column(
          children: [
            // 🔷 Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔷 Body Content with Collapsible Sections
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Introduction',
                      content:
                          'We are committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our services. Please read this policy carefully to understand our practices regarding your personal data.',
                      sectionKey: 'introduction',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Data Collection',
                      content:
                          'We collect information you provide directly, such as your name, email address, and preferences, as well as data collected automatically, like IP addresses, browser types, and cookies. This helps us improve our services and provide a personalized experience.',
                      sectionKey: 'dataCollection',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Data Usage',
                      content:
                          'Your data is used to enhance your experience, process transactions, and communicate with you. We may also use anonymized data for analytics to understand user trends and improve our platform.',
                      sectionKey: 'dataUsage',
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Your Rights',
                      content:
                          'You have the right to access, correct, or delete your personal data. You may also opt out of certain data collection practices, such as cookies, by adjusting your browser settings or contacting us directly.',
                      sectionKey: 'userRights',
                    ),
                    const SizedBox(height: 24),
                    // 🔷 Footer with Last Updated
                    const Text(
                      'Last Updated: August 13, 2025',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔷 Helper method to build collapsible sections
  Widget _buildSection({
    required String title,
    required String content,
    required String sectionKey,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color:  Colors.cyan,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor:const Color(0xFF10214B), // Removes divider lines
        ),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.normal,
              color: Color(0xFF10214B),
            ),
          ),
          initiallyExpanded: _expandedSections[sectionKey] ?? false,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedSections[sectionKey] = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color:Color(0xFF10214B),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}