import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wear_space/screens/product_detail_screen.dart';
import 'package:wear_space/screens/sell_page.dart';

// ProductNotifier for notifying product changes
class ProductNotifier extends ChangeNotifier {
  void notifyProductChange() {
    notifyListeners();
  }
}

final productNotifier = ProductNotifier();

class UploadedProductsPage extends StatefulWidget {
  const UploadedProductsPage({super.key});

  @override
  State<UploadedProductsPage> createState() => _UploadedProductsPageState();
}

class _UploadedProductsPageState extends State<UploadedProductsPage> {
  List<Map<String, dynamic>> _products = [];
  bool _isProductsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isProductsLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user logged in'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
        return;
      }
      final products = await Supabase.instance.client
          .from('products')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false);
      if (products.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No products found.'),
            backgroundColor: Color(0xFF10214B),
          ),
        );
      }
      // Decode extra_fields and ensure keys are strings
      final decodedProducts = products.map((product) {
        if (product['extra_fields'] is String) {
          try {
            product['extra_fields'] = jsonDecode(product['extra_fields']);
          } catch (e) {
            print('Error decoding extra_fields for product ${product['id']}: $e');
            product['extra_fields'] = {};
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invalid data format for product ${product['id']}'),
                  backgroundColor: const Color(0xFF10214B),
                ),
              );
            }
          }
        } else if (product['extra_fields'] is! Map?) {
          product['extra_fields'] = {};
        }
        // Convert keys to strings and ensure values are strings
        if (product['extra_fields'] is Map) {
          product['extra_fields'] = (product['extra_fields'] as Map).map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
        }
        print('Product ${product['id']} extra_fields: ${product['extra_fields']}');
        return product;
      }).toList();
      setState(() {
        _products = decodedProducts;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProductsLoading = false);
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', productId);
      await _loadProducts();
      productNotifier.notifyProductChange();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully.'),
            backgroundColor: Color(0xFF10214B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: $e'),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back arrow and title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Color(0xFF10214B)),
                        tooltip: 'Back',
                      ),
                      const Text(
                        'Your Products',
                        style: TextStyle(
                          color: Color(0xFF10214B),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _isProductsLoading
                        ? null
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SellPage()),
                            );
                            await _loadProducts();
                            productNotifier.notifyProductChange();
                          },
                    icon:
                        const Icon(Icons.add_circle_outline, color: Color(0xFF10214B)),
                    tooltip: 'List New Product',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Products list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isProductsLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF10214B)))
                    : _products.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Center(
                              child: Text(
                                'No products listed yet.',
                                style: TextStyle(
                                  color: Color(0xFF10214B),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              final extraFields = product['extra_fields'] is Map
                                  ? Map<String, dynamic>.from(product['extra_fields']
                                      .map((k, v) => MapEntry(k.toString(), v)))
                                  : <String, dynamic>{};
                              final extraInfo = extraFields.entries
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(', ');
                              return Dismissible(
                                key: Key(
                                    product['id']?.toString() ?? index.toString()),
                                onDismissed: (direction) =>
                                    _deleteProduct(product['id']?.toString() ?? ''),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10214B),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                child: Container(
                                  width: MediaQuery.of(context).size.width - 24,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    dense: true,
                                    leading: product['image_url'] != null &&
                                            product['image_url'].toString().isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: product['image_url'].toString(),
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) =>
                                                  const Icon(
                                                Icons.image_not_supported,
                                                color: Color(0xFF10214B),
                                                size: 40,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.inventory,
                                            color: Color(0xFF10214B), size: 24),
                                    title: Text(
                                      product['title']?.toString() ?? 'Untitled Product',
                                      style: const TextStyle(
                                        color: Color(0xFF10214B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${product['category']?.toString() ?? 'Unknown'} - ₦${(product['price'] != null ? product['price'].toStringAsFixed(2) : '0.00')}${extraInfo.isNotEmpty ? '\n$extraInfo' : ''}',
                                      style: const TextStyle(
                                        color: Color(0xFF10214B),
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailsScreen(
                                            name: product['title']?.toString() ??
                                                'Untitled Product',
                                            price:
                                                '₦${(product['price'] != null ? product['price'].toStringAsFixed(2) : '0.00')}',
                                            imageUrl: product['image_url']?.toString() ??
                                                'https://via.placeholder.com/150',
                                            productType:
                                                product['category']?.toString() ??
                                                    'Unknown',
                                            businessName:
                                                extraFields['name']?.toString() ??
                                                    'Unknown Seller',
                                            location:
                                                extraFields['location']?.toString() ??
                                                    '',
                                            phoneNumber:
                                                product['phone']?.toString() ?? '',
                                            sellerAvatar:
                                                extraFields['seller_avatar']?.toString() ??
                                                    'https://via.placeholder.com/100',
                                            description:
                                                extraFields['description']?.toString() ??
                                                    '',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}