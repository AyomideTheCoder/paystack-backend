import 'package:flutter/material.dart';
import 'package:wear_space/screens/sell_page.dart';
import '../home_screen.dart';
import 'categories_page.dart';
// ✅ Corrected import
import 'chat_list_page.dart';
import 'profile_page.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Naija Market Navigation'),
        backgroundColor: const Color(0xFF10214B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton(context, 'Go to Home Page', const HomeScreen()),
            const SizedBox(height: 16),
            buildButton(context, 'Go to Categories Page',  const CategoriesPage()),
            const SizedBox(height: 16),
            buildButton(context, 'Go to Sell Page',   const SellPage()),
            const SizedBox(height: 16), 
           buildButton(context, 'Go to Chat List Page',    const ChatListPage()),
            const SizedBox(height: 16), 
            buildButton(context, 'Go to Profile Page',     ProfilePage()),
            const SizedBox(height: 16), 
          ],
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context, String label, Widget page) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFF10214B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
