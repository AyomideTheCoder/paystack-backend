import 'dart:convert'; // Added for jsonDecode
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'product_detail_screen.dart'; // Adjust import based on your project structure

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Map<String, dynamic>> _wishlistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to view your wishlist')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('wishlist')
          .select('product_id, products(title, image_url, price, category, product_description, location, phone, seller_avatar, user_id, extra_fields)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _wishlistItems = List<Map<String, dynamic>>.from(response);
        for (var item in _wishlistItems) {
          if (item['products']?['extra_fields'] is String) {
            try {
              item['products']['extra_fields'] = jsonDecode(item['products']['extra_fields']);
            } catch (e) {
              debugPrint('Error decoding extra_fields for product ${item['product_id']}: $e');
              item['products']['extra_fields'] = {};
            }
          } else if (item['products']?['extra_fields'] == null) {
            item['products']['extra_fields'] = {};
          }
        }
        _isLoading = false;
      });
      debugPrint('Wishlist items loaded: ${_wishlistItems.length}');
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wishlist: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('wishlist')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);

      setState(() {
        _wishlistItems.removeWhere((item) => item['product_id'] == productId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist')),
        );
      }
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing from wishlist: $e')),
        );
      }
    }
  }

  void _navigateToProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          productId: product['product_id'] ?? '',
          sellerId: product['products']['user_id'] ?? '',
          name: product['products']['title'] ?? 'No Title',
          imageUrl: product['products']['image_url'] ?? '',
          price: product['products']['price']?.toString() ?? '0',
          productType: product['products']['category'] ?? '',
          businessName: product['products']['extra_fields']?['name'] ?? product['products']['name'] ?? 'Unknown Seller',
          location: product['products']['location'] ?? '',
          phoneNumber: product['products']['phone'] ?? '',
          sellerAvatar: product['products']['seller_avatar'] ?? 'https://via.placeholder.com/150',
          description: product['products']['product_description'] ?? '',
        ),
      ),
    ).then((_) => _loadWishlist()); // Refresh wishlist after returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: const Color(0xFF10214B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wishlistItems.isEmpty
              ? const Center(child: Text('Your wishlist is empty'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _wishlistItems.length,
                  itemBuilder: (context, index) {
                    final item = _wishlistItems[index];
                    final product = item['products'];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CachedNetworkImage(
                          imageUrl: product['image_url'] ?? 'https://via.placeholder.com/150',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                        ),
                        title: Text(product['title'] ?? 'No Title'),
                        subtitle: Text('₦${product['price']?.toString() ?? '0'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFromWishlist(item['product_id']),
                        ),
                        onTap: () => _navigateToProductDetails(item),
                      ),
                    );
                  },
                ),
    );
  }
}