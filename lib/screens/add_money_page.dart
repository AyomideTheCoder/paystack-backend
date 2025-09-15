import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wear_space/services/api_service.dart' show PaymentService;
import 'package:wear_space/screens/payment_confirmation_page.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Added for URL launching
import 'package:flutter/foundation.dart' show kIsWeb;

class AddMoneyPage extends StatelessWidget {
  const AddMoneyPage({super.key});

  Future<void> _showConfirmationDialog(BuildContext context, String action, {String? reference, double? amount}) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Successful'),
        content: Text(
          action == 'Copied'
              ? 'Account number copied. Please transfer to the account.'
              : action == 'Shared'
                  ? 'Account details shared. Please transfer to the account.'
                  : '₦${amount?.toStringAsFixed(2)} added to your wallet. Reference: $reference',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF10214B))),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10214B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(label: '$title Icon', child: Icon(icon, color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: title,
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            Semantics(label: 'Navigate to $title', child: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFF10214B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.account_balance, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text('Bank Transfer', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Transfer to the account below to fund your wallet', style: TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 12),
                const Text('Naija Market Account Number', style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                const Text('1234 5678 9012', style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await Clipboard.setData(const ClipboardData(text: '123456789012'));
                            await _showConfirmationDialog(context, 'Copied');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to copy: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF10214B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Copy Number'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await Share.share(
                              'Naija Market Wallet Funding\nAccount Number: 1234 5678 9012\nBank: Naija Bank',
                              subject: 'Naija Market Account Details',
                            );
                            await _showConfirmationDialog(context, 'Shared');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF10214B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Share Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Other Funding Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10214B))),
          const SizedBox(height: 16),
          _buildMethodCard(
            context: context,
            icon: Icons.credit_card,
            title: 'Top-up with Card',
            description: 'Use your bank card to top-up instantly.',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CardTopUpScreen()));
            },
          ),
          _buildMethodCard(
            context: context,
            icon: Icons.phone_android,
            title: 'Bank USSD',
            description: 'Dial your bank USSD to fund your wallet quickly.',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const USSDScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class CardTopUpScreen extends StatefulWidget {
  const CardTopUpScreen({super.key});

  @override
  State<CardTopUpScreen> createState() => _CardTopUpScreenState();
}

class _CardTopUpScreenState extends State<CardTopUpScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;
  final _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _makePayment(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = (double.parse(_amountController.text) * 100).toInt(); // Convert NGN to kobo
      debugPrint('Initial amount entered (kobo): $amount'); // Debug: Amount in kobo

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Initialize transaction
      debugPrint('Starting initializeTransaction with amount (kobo): $amount'); // Debug: Before API call
      final result = await _paymentService.initializeTransaction(
        user.email ?? 'test@example.com',
        amount,
      );
      debugPrint('initializeTransaction result: ${result.toString()}'); // Debug: API response

      final authUrl = result['authorization_url'];
      final reference = result['reference'];
      debugPrint('Auth URL: $authUrl, Reference: $reference'); // Debug: Payment details

      if (kIsWeb) {
        if (await canLaunch(authUrl)) {
          await launch(authUrl);
          await _verifyAndCompletePayment(context, reference, amount / 100); // Convert back to NGN for display
        } else {
          throw Exception('Could not launch URL: $authUrl');
        }
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              authUrl: authUrl,
              onPaymentComplete: () => _verifyAndCompletePayment(context, reference, amount / 100), // Convert back to NGN
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Payment error caught: $e'); // Debug: Catch any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndCompletePayment(BuildContext context, String reference, double amount) async {
    try {
      debugPrint('Verifying payment with reference: $reference'); // Debug: Start verification
      final verified = await _paymentService.verifyTransaction(reference);
      if (verified != null && verified['status'] == 'success') {
        debugPrint('Payment verified: $verified'); // Debug: Verification success
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationPage(
              reference: reference,
              amount: amount,
            ),
          ),
        );
      } else {
        throw Exception('Payment verification failed');
      }
    } catch (e) {
      debugPrint('Verification error: $e'); // Debug: Catch verification errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top-up with Card'),
        backgroundColor: const Color(0xFF10214B),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10214B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (₦)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF10214B)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid positive amount';
                      }
                      if (amount < 100) {
                        return 'Minimum amount is ₦100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _makePayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10214B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Pay with Paystack',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

class WebViewScreen extends StatefulWidget {
  final String authUrl;
  final Future<void> Function() onPaymentComplete;

  const WebViewScreen({super.key, required this.authUrl, required this.onPaymentComplete});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.contains('success') || request.url.contains('your-app-callback.com')) {
              await widget.onPaymentComplete(); // Trigger verification
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment'), backgroundColor: const Color(0xFF10214B)),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class USSDScreen extends StatelessWidget {
  const USSDScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank USSD'), backgroundColor: const Color(0xFF10214B)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fund Your Wallet with USSD',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10214B)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dial the USSD code for your bank to transfer funds to your Naija Market wallet.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            const Text(
              'Account Number: 1234 5678 9012\nBank: Naija Bank',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            const Text(
              'Common Bank USSD Codes:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '- GTBank: *737#\n- Zenith Bank: *966#\n- First Bank: *894#\n- UBA: *919#',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Optionally launch dialer with a USSD code
                // e.g., launch('tel:*737#');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please dial the USSD code for your bank')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10214B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Open Dialer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}