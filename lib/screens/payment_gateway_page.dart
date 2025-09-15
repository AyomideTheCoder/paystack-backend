import 'package:flutter/material.dart';
import 'package:wear_space/screens/add_money_page.dart';
import 'package:wear_space/screens/payment_screen.dart';
import 'package:wear_space/screens/wallet_activity_page.dart';

class PaymentGatewayPage extends StatefulWidget {
  const PaymentGatewayPage({super.key});

  @override
  State<PaymentGatewayPage> createState() => _PaymentGatewayPageState();
}

class _PaymentGatewayPageState extends State<PaymentGatewayPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 19,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
          splashRadius: 20,
        ),
        backgroundColor: const Color(0xFF10214B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.25,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Your Payment Hub',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10214B),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your finances seamlessly with Wear Space. Deposit funds, send money to friends or vendors, and track your transactions all in one place. Enjoy secure and fast payments with our trusted platform.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: const Color(0xFF10214B),
              unselectedLabelColor: const Color(0xFF4B5563),
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              indicator: CustomTabIndicator(),
              labelPadding: const EdgeInsets.only(bottom: 2), // Tiny space between tabs and indicator
              tabs: const [
                Tab(text: 'Deposit'),
                Tab(text: 'Transfer'),
                Tab(text: 'Transactions'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                AddMoneyPage(),
                PaymentScreen(),
                WalletActivityPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTabIndicator extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomTabIndicatorPainter();
  }
}

class _CustomTabIndicatorPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = const Color(0xFF10214B)
      ..strokeWidth = 4; // Thicker indicator
    final double width = configuration.size!.width;
    final double y = configuration.size!.height; // Position at very bottom to sit under tabs
    canvas.drawLine(
      Offset(offset.dx, y),
      Offset(offset.dx + width, y),
      paint,
    );
  }
}