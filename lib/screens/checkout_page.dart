import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Order Confirmation',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Elitewheels Official Store',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.network(
                              'https://i.imgur.com/QCNbOAo.png',
                              width: 80,
                              height: 80,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Elitewheels EDGE Ultralight 1314g Road Disc',
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                  Text(
                                    'Steel Bearing, 40mm, CHINA, Inner width 21mm, SHIMANO 10-11-12S, Tubeless compatible',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    'NGN942,072.14',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Shipping: NGN1,550,908.88',
                              style: TextStyle(fontSize: 14),
                            ),
                            IconButton(
                              icon: const Icon(Icons.message, color: Colors.green),
                              onPressed: () {
                                // Add logic to open chat with seller
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Contacting Elitewheels Official Store')),
                                );
                              },
                            ),
                          ],
                        ),
                        const Text(
                          'Delivery: Oct. 06 (Seller-arranged)',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Choice Shop104965082 Store',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.network(
                              'https://i.imgur.com/QCNbOAo.png',
                              width: 80,
                              height: 80,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'High Quality labob-V4 Blind Box World Plush Ke...',
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                  Text(
                                    '1 pcs',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    'NGN11,397.50',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Shipping: NGN3,335.04',
                              style: TextStyle(fontSize: 14),
                            ),
                            IconButton(
                              icon: const Icon(Icons.message, color: Colors.green),
                              onPressed: () {
                                // Add logic to open chat with seller
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Contacting Choice Shop104965082 Store')),
                                );
                              },
                            ),
                          ],
                        ),
                        const Text(
                          'Total: NGN2,507,713.56',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Delivery: Seller-arranged',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment will be arranged with the seller',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.payment),
                            SizedBox(width: 5),
                            Text('Visa', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 10),
                            Text('Mastercard', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 10),
                            Text('Verve', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 10),
                            Text('JCB', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 10),
                            Text('Palmpay', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.phone_android),
                            SizedBox(width: 5),
                            Text('OPay', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.paypal),
                            SizedBox(width: 5),
                            Text('PayPal', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Summary',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Items total', style: TextStyle(fontSize: 14)),
                      Text('NGN1,428,872.83', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Items discount', style: TextStyle(fontSize: 14)),
                      Text('NGN475,403.19', style: TextStyle(fontSize: 14, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: TextStyle(fontSize: 14)),
                      Text('NGN953,469.64', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Promo codes', style: TextStyle(fontSize: 14)),
                      Text('Enter >', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Shipping fee', style: TextStyle(fontSize: 14)),
                      Text('NGN1,554,243.92', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Security & Privacy', style: TextStyle(fontSize: 14)),
                      Text('>', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Safe payments  Secure personal details',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Note: Delivery and payment are managed by the seller. Service is not fully available yet.',
                    style: TextStyle(fontSize: 14, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _isChecked = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Upon clicking \'Place Order\', I confirm I have read and acknowledged all terms and policies.',
                        style: TextStyle(fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null, // Disabled until delivery and payment are implemented
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 3, 105, 7),
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Place order',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}