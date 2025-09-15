import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _narrationController = TextEditingController();
  final _supabase = Supabase.instance.client;
  String? _selectedBank;
  bool _isLoading = false;

  final List<String> _banks = [
    'Access Bank', 'Citibank Nigeria', 'Ecobank Nigeria', 'Fidelity Bank',
    'First Bank of Nigeria', 'First City Monument Bank (FCMB)', 'Globus Bank',
    'Guaranty Trust Bank (GTB)', 'Heritage Bank', 'Keystone Bank', 'Kuda Bank',
    'Opay', 'PalmPay', 'Polaris Bank', 'Providus Bank', 'Stanbic IBTC Bank',
    'Standard Chartered Bank', 'Sterling Bank', 'Union Bank of Nigeria',
    'United Bank for Africa (UBA)', 'Unity Bank', 'Wema Bank', 'Zenith Bank',
  ];

  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final accountNumber = _accountNumberController.text;
    final bank = _selectedBank!;
    final amount = double.parse(_amountController.text);
    final narration = _narrationController.text;

    try {
      // Fetch current user balance
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userData = await _supabase.from('users').select('balance').eq('id', user.id).maybeSingle();
      final currentBalance = (userData?['balance'] as num?)?.toDouble() ?? 0.0;

      // Check for sufficient balance
      if (amount > currentBalance) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient balance'), backgroundColor: Colors.red),
        );
        return;
      }

      // Generate unique transaction reference
      final reference = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      // Insert transaction
      await _supabase.from('transactions').insert({
        'sender_id': user.id,
        'account_number': accountNumber,
        'bank': bank,
        'amount': amount,
        'narration': narration,
        'reference': reference,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Deduct from sender wallet
      await _supabase.from('users').update({'balance': currentBalance - amount}).eq('id', user.id);

      // Optional: update recipient balance if integrated
      // await _supabase.from('users').update({'balance': Supabase.raw('balance + $amount')}).eq('account_number', accountNumber);

      setState(() => _isLoading = false);

      _showConfirmationDialog(accountNumber, bank, amount, narration, reference);

      // Clear form
      _accountNumberController.clear();
      _amountController.clear();
      _narrationController.clear();
      setState(() => _selectedBank = null);

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showConfirmationDialog(String accountNumber, String bank, double amount, String narration, String reference) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2DD4BF), size: 60),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10214B)),
            ),
            const SizedBox(height: 8),
            Text(
              '₦${amount.toStringAsFixed(2)} sent to $accountNumber ($bank)',
              style: const TextStyle(fontSize: 16, color: Color(0xFF10214B)),
              textAlign: TextAlign.center,
            ),
            if (narration.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Narration: $narration', style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 8),
            Text('Reference: $reference', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            Text('Date: ${DateFormat('MMM dd, yyyy, hh:mm a').format(DateTime.now())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10214B))),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                hintText: 'Enter 10-digit account number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 2)),
                prefixIcon: const Icon(Icons.account_balance, color: Color(0xFF10214B)),
                filled: true, fillColor: Colors.grey[100], counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 10,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter an account number';
                if (value.length != 10) return 'Account number must be 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Bank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10214B))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedBank,
              hint: const Text('Select a bank'),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 2)),
                filled: true, fillColor: Colors.grey[100], prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF10214B)),
              ),
              items: _banks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
              onChanged: (value) => setState(() => _selectedBank = value),
              validator: (value) => value == null ? 'Please select a bank' : null,
              isExpanded: true, dropdownColor: Colors.white, menuMaxHeight: 300,
            ),
            const SizedBox(height: 16),
            const Text('Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10214B))),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                hintText: 'Enter amount in ₦',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 2)),
                prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF10214B)),
                filled: true, fillColor: Colors.grey[100],
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter an amount';
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) return 'Please enter a valid positive amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Narration (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10214B))),
            const SizedBox(height: 8),
            TextFormField(
              controller: _narrationController,
              decoration: InputDecoration(
                hintText: 'Add a narration',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 2)),
                prefixIcon: const Icon(Icons.note_add, color: Color(0xFF10214B)),
                filled: true, fillColor: Colors.grey[100],
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10214B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4, shadowColor: Colors.black45,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text('Send Money', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
