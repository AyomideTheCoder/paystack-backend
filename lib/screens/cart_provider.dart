import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final String imageUrl;
  final String productType;
  final double price;

  CartItem({
    required this.name,
    required this.imageUrl,
    required this.productType,
    required this.price,
  });
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  void addToCart(CartItem item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  double get totalPrice => _cartItems.fold(0, (sum, item) => sum + item.price);
}