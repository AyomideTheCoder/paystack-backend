import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wear_space/services/api_service.dart' show PaymentService;

class PaymentConfirmationPage extends StatefulWidget {
  final String reference;
  final double amount;

  const PaymentConfirmationPage({
    super.key,
    required this.reference,
    required this.amount,
  });

  @override
  _PaymentConfirmationPageState createState() =>
      _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  final PaymentService _paymentService = PaymentService();
  final _supabase = Supabase.instance.client;
  bool _isVerifying = true;
  bool _isSuccess = false;
  String _message = '';
  String _transactionDetails = '';

  @override
  void initState() {
    super.initState();
    _verifyPayment();
  }

  Future<void> _verifyPayment() async {
    try {
      final result = await _paymentService.verifyTransaction(widget.reference);
      setState(() {
        _isVerifying = false;
        _isSuccess = result['status'] == 'success';
        _message = _isSuccess
            ? 'Your payment has been made!'
            : 'Payment failed: ${result['message'] ?? 'Unknown error'}';
        _transactionDetails = _isSuccess
            ? 'Amount: ₦${widget.amount.toStringAsFixed(2)}\nReference: ${widget.reference}'
            : '';
      });

      if (_isSuccess) {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final currentBalanceResponse = await _supabase
              .from('users')
              .select('balance')
              .eq('id', user.id)
              .maybeSingle();

          final currentBalance =
              (currentBalanceResponse?['balance'] as num?)?.toDouble() ?? 0.0;

          await _supabase.from('users').update({
            'balance': currentBalance + widget.amount,
          }).eq('id', user.id);

          await _supabase.from('transactions').insert({
            'user_id': user.id,
            'amount': widget.amount,
            'type': 'credit',
            'title': 'Wallet Funding',
            'reference': widget.reference,
            'status': 'completed',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _message = 'Error verifying payment: $e';
        _transactionDetails = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _isSuccess ? 'Payment Successful' : 'Payment Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isSuccess ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 48,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isVerifying) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    const Text(
                      'Verifying payment...',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error,
                      color: _isSuccess ? Colors.green : Colors.red,
                      size: 80,
                      semanticLabel: _isSuccess
                          ? 'Payment successful'
                          : 'Payment failed',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _message,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isSuccess
                          ? 'Your payment has gone through. It should be received in a few minutes.\n\n$_transactionDetails'
                          : 'Please try again or contact support.',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (!_isSuccess) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Retry Payment',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/main',
                            (route) => false,
                            arguments: 0,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004d40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Return to Home',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
