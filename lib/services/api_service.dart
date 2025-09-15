import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String _baseUrl = 'https://paystack-backend-b4k7.onrender.com'; // Your Render URL

  // Initialize a transaction
  Future<Map<String, dynamic>> initializeTransaction(String email, int amount) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/initialize-transaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'amount': amount * 100, // Paystack expects amount in kobo (multiply by 100)
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initialize transaction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error initializing transaction: $e');
    }
  }

  // Verify a transaction
  Future<Map<String, dynamic>> verifyTransaction(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/verify-transaction?reference=$reference'), // Match GET with query param
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data; // Return full response including amount and customer
        } else {
          throw Exception('Verification failed: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to verify transaction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error verifying transaction: $e');
    }
  }
}