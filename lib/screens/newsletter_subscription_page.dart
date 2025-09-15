import 'package:flutter/material.dart';

class NewsletterSubscriptionPage extends StatefulWidget {
  const NewsletterSubscriptionPage({super.key});

  @override
  State<NewsletterSubscriptionPage> createState() => _NewsletterSubscriptionPageState();
}

class _NewsletterSubscriptionPageState extends State<NewsletterSubscriptionPage> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void subscribe() {
    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();

      // TODO: Add real subscription logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscribed with $email')),
      );

      emailController.clear();
    }
  }

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
                  'Newsletter Subscription',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // 🔷 Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Container(
                padding: const EdgeInsets.all(24),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.mark_email_read_rounded, size: 50, color: Color(0xFF004d40)),
                      const SizedBox(height: 20),
                      const Text(
                        'Stay Updated!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Subscribe to get exclusive deals, updates, and discounts straight to your inbox.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 30),

                      // 📨 Email Field with Validation
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailPattern.hasMatch(value.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email, color: Color(0xFF004d40)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF004d40)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ✅ Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: subscribe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004d40),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Subscribe',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
