// transaction_details_page.dart
import 'package:flutter/material.dart';

class TransactionDetailsPage extends StatelessWidget {
  final String transactionId;
  const TransactionDetailsPage({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: $transactionId', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text('Date: July 16, 2025'),
            const Text('Amount: ₦58,240.75'),
            const Text('Status: Completed'),
            const Text('Payment Method: Wallet'),
            const SizedBox(height: 20),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• 2x Taylor Plush 4‑Piece'),
            const Text('• 1x Stylish Outfit'),
          ],
        ),
      ),
    );
  }
}