import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Add this package for futuristic icons
// Prefix to avoid ChatPage conflict
import '../home_screen.dart';
import 'categories_page.dart';
import 'sell_page.dart';
import 'chat_list_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _screens = [
      const HomeScreen(), // Home
      const CategoriesPage(), // Shop (reusing CategoriesPage as a placeholder for Shop)
      const SellPage(),
      const ChatListPage(),
       ProfilePage(), // Messages (prefixed to ensure correct usage)
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF10214B),
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        iconSize: 26,
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            activeIcon: Icon(Iconsax.home_1), // Bold version for active state
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.shop),
            activeIcon: Icon(Iconsax.shop_add), // Slightly modified for active state
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.money_send),
            activeIcon: Icon(Iconsax.money_recive), // Dynamic alternative for active state
            label: 'Sell',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.message),
            activeIcon: Icon(Iconsax.message_text_1), // Enhanced version for active state
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.profile_circle),
            activeIcon: Icon(Iconsax.profile_2user), // Enhanced version for active state
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}