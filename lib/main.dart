import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart'; // Added for URL launching
import 'package:wear_space/screens/add_money_page.dart';
import 'package:wear_space/screens/chat_list_page.dart';
import 'package:wear_space/screens/forgot_password_page.dart';
import 'package:wear_space/screens/splash_screen.dart';
import 'package:wear_space/screens/main_screen.dart';
import 'package:wear_space/screens/my_orders_page.dart';
import 'package:wear_space/screens/contact_us_page.dart';
import 'package:wear_space/screens/privacy_policy_page.dart';
import 'package:wear_space/screens/terms_conditions_page.dart';
import 'package:wear_space/screens/newsletter_subscription_page.dart';
import 'package:wear_space/screens/enter_pin_page.dart';
import 'package:wear_space/screens/change_password_screen.dart';
import 'package:wear_space/screens/sell_page.dart';
import 'package:wear_space/screens/notification_service.dart';
import 'package:wear_space/screens/notifications_page.dart';
import 'package:wear_space/screens/profile_page.dart';
import 'package:iconsax/iconsax.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Setup WebView only for Android/iOS
  if (!kIsWeb) {
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (Platform.isIOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }

  /// Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('productsBox');

  /// Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://wwqeulonhjjnnsxngosm.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind3cWV1bG9uaGpqbm5zeG5nb3NtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTA5NDIsImV4cCI6MjA3MTI2Njk0Mn0.WJwfkq-PtO3xc518yaGYDHQFJVS06F_qHmBF_s5Cdjw',
      debug: false,
    );
    debugPrint('✅ Supabase initialized');
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
  }

  /// Load .env file
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ Could not load .env: $e');
  }

  /// Initialize notifications
  await NotificationService().initialize();

  runApp(const WearSpaceApp());
}

class WearSpaceApp extends StatelessWidget {
  const WearSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wear Space',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        fontFamily: 'Montserrat',
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.grey.shade100,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF10214B),
          elevation: 4,
        ),
      ),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/home_screen':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/contact_us':
            return MaterialPageRoute(builder: (_) => const ContactUsPage());
          case '/privacy_policy':
            return MaterialPageRoute(builder: (_) => const PrivacyPolicyPage());
          case '/terms_conditions':
            return MaterialPageRoute(builder: (_) => const TermsConditionsPage());
          case '/newsletter_subscription':
            return MaterialPageRoute(builder: (_) => const NewsletterSubscriptionPage());
          case '/my_orders':
            return MaterialPageRoute(builder: (_) => const MyOrdersPage());
          case '/enterPin':
            return MaterialPageRoute(builder: (_) => const EnterPinPage());
          case '/change-password':
            return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
          case '/sell':
            return MaterialPageRoute(builder: (_) => const SellPage());
          case '/Forgot-password':
            return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
          case '/main':
            final initialIndex = settings.arguments as int? ?? 0;
            return MaterialPageRoute(builder: (_) => MainScreen(initialIndex: initialIndex));
          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsPage());
          case '/add_money':
            debugPrint('Navigating to AddMoneyPage');
            return MaterialPageRoute(builder: (_) => const AddMoneyPage());
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('Route ${settings.name} not found')),
              ),
            );
        }
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeDefaultData();
  }

  Future<void> _initializeDefaultData() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (session == null || (session.expiresAt != null && session.expiresAt! < now)) {
        try {
          await Supabase.instance.client.auth.refreshSession();
          debugPrint('✅ Session refreshed successfully');
        } catch (e) {
          debugPrint('❌ Session refresh failed: $e');
        }
      }

      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'default_user';
      debugPrint('Initializing default data for user: $userId');

      final homeMessages = await Supabase.instance.client
          .from('home_messages')
          .select()
          .eq('user_id', userId)
          .limit(1);

      if (homeMessages.isEmpty) {
        await Supabase.instance.client.from('home_messages').insert([
          {
            'user_id': userId,
            'message': 'Welcome to Naija Market!',
            'timestamp': DateTime.now().toIso8601String()
          },
          {
            'user_id': userId,
            'message': 'Explore new offers here!',
            'timestamp': DateTime.now().toIso8601String()
          },
        ]);
        debugPrint('✅ Inserted default home messages');
      }

      final shopProducts = await Supabase.instance.client
          .from('shop_products')
          .select()
          .eq('user_id', userId)
          .limit(1);

      if (shopProducts.isEmpty) {
        await Supabase.instance.client.from('shop_products').insert([
          {
            'user_id': userId,
            'product': 'Browse Products from Sellers!',
            'timestamp': DateTime.now().toIso8601String()
          },
        ]);
        debugPrint('✅ Inserted default shop products');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize default data: $e');
    }
  }

  final List<Widget> _pages = [
    const HomeTab(),
    const ShopTab(),
    const SellPage(),
    const ChatListPage(),
     ProfilePage(),
    const AddMoneyPage(),
  ];

  final List<BottomNavigationBarItem> _navBarItems = const [
    BottomNavigationBarItem(icon: Icon(Iconsax.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Iconsax.shop), label: 'Shop'),
    BottomNavigationBarItem(icon: Icon(Iconsax.add_square), label: 'Sell'),
    BottomNavigationBarItem(icon: Icon(Iconsax.message), label: 'Message'),
    BottomNavigationBarItem(icon: Icon(Iconsax.profile_2user), label: 'Profile'),
    BottomNavigationBarItem(icon: Icon(Iconsax.wallet), label: 'Wallet'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      debugPrint('Navigated to tab: ${_navBarItems[index].label}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WearSpace'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.notification),
            onPressed: () {
              debugPrint('Navigating to NotificationsPage');
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navBarItems,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF10214B),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'default_user';
    debugPrint('HomeTab: Loading home_messages for user: $userId');
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('home_messages')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('HomeTab error: ${snapshot.error}');
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        final messages = snapshot.data?.map((doc) => doc['message'] as String).toList() ?? [];
        if (messages.isEmpty) {
          return const Center(child: Text('No messages available'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: messages.asMap().entries.map((entry) {
            final msg = entry.value;
            return GestureDetector(
              onTap: () async {
                try {
                  await NotificationService().showNotification('Home Message Viewed', 'You viewed: $msg');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send notification: $e'),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Text(msg, style: const TextStyle(fontSize: 18)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'default_user';
    debugPrint('ShopTab: Loading shop_products for user: $userId');
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('shop_products')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        final products = snapshot.data?.map((doc) => doc['product'] as String).toList() ?? [];
        if (products.isEmpty) {
          return const Center(child: Text('No products available'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: products.asMap().entries.map((entry) {
            final prod = entry.value;
            return GestureDetector(
              onTap: () async {
                try {
                  await NotificationService().showNotification('Product Viewed', 'You viewed: $prod');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send notification: $e'),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Text(prod, style: const TextStyle(fontSize: 18)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}