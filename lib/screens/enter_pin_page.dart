import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnterPinPage extends StatefulWidget {
  const EnterPinPage({super.key});

  @override
  _EnterPinPageState createState() => _EnterPinPageState();
}

class _EnterPinPageState extends State<EnterPinPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void deleteDigit() {
    // No PIN to delete, but keep for consistency
    HapticFeedback.lightImpact();
  }

  Widget buildKeypadButton(String value, {bool isBackspace = false}) {
    return GestureDetector(
      onTap: () {
        if (isBackspace) {
          HapticFeedback.lightImpact();
          deleteDigit();
        } else if (value.isNotEmpty) {
          HapticFeedback.lightImpact();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: isBackspace
              ? const Icon(Icons.backspace_outlined, color: Color(0xFF004d40), size: 24)
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004d40),
                  ),
                ),
        ),
      ),
    );
  }

  Widget buildKeypad() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['1', '2', '3', '4'].map((val) => buildKeypadButton(val)).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['5', '6', '7', '8'].map((val) => buildKeypadButton(val)).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 60, height: 60), // Placeholder
            buildKeypadButton('0'),
            buildKeypadButton('', isBackspace: true),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.payment,
              size: 60,
              color: Color(0xFF004d40),
            ),
            const SizedBox(height: 20),
            const Text(
              "Payment Confirmation",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004d40),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 1.5),
                        color: index < 0 ? Colors.transparent : Colors.green, // Static for now
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 40),
            buildKeypad(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/order-confirmation');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004d40),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Pay",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}