import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // 🔷 Header
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF004d40),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // 🔷 Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please Read Carefully',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'By using this app, you agree to the following terms and conditions:',
                      style: TextStyle(fontSize: 15.5, height: 1.6, color: Colors.black87),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'User Responsibilities',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '- Provide accurate and truthful information\n'
                      '- Keep your login credentials safe\n'
                      '- Do not misuse the platform',
                      style: TextStyle(height: 1.5),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Payments & Orders',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '- All transactions are final once confirmed\n'
                      '- Refunds may apply under special conditions\n'
                      '- Delivery timelines are estimates only',
                      style: TextStyle(height: 1.5),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Legal',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '- We reserve the right to ban accounts violating our terms\n'
                      '- Content you post must not infringe on copyrights\n'
                      '- Terms may be updated with prior notice',
                      style: TextStyle(height: 1.5),
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
