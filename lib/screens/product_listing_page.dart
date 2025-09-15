import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wear_space/screens/product_detail_screen.dart'; // Adjust path
import 'dart:convert';

class ProductListingPage extends StatefulWidget {
  final String categoryName;

  const ProductListingPage({
    super.key,
    required this.categoryName,
  });

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  List<Map<String, dynamic>> _cachedProducts = [];
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF10214B)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  title: Text(
                    widget.categoryName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10214B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 🔍 Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10214B),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.white70),
                      hintText: 'Search item or store...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.categoryName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10214B),
                  ),
                ),
                const SizedBox(height: 16),
                // 🔄 Products stream with caching
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: widget.categoryName == 'Explore'
                      ? Supabase.instance.client
                          .from('products')
                          .stream(primaryKey: ['id'])
                          .order('timestamp', ascending: false)
                      : Supabase.instance.client
                          .from('products')
                          .stream(primaryKey: ['id'])
                          .eq('category', widget.categoryName)
                          .order('timestamp', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint('Supabase error: ${snapshot.error}');
                      return const Center(
                        child: Text(
                          'Error loading products.',
                          style: TextStyle(color: Color(0xFF10214B), fontSize: 16),
                        ),
                      );
                    }

                    // 🔹 Always start with cache
                    var products = _cachedProducts;

                    // 🔹 If Supabase has new data, update cache + UI
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      products = snapshot.data!;
                      _cachedProducts = products;
                    }

                    if (products.isEmpty) {
                      return const Center(
                        child: Text(
                          'No products listed yet.',
                          style: TextStyle(color: Color(0xFF10214B), fontSize: 16),
                        ),
                      );
                    }

                    // 🔍 Apply search filter
                    final filteredProducts = products.where((product) {
                      final title = (product['title'] ?? '').toString().toLowerCase();
                      final category = (product['category'] ?? '').toString().toLowerCase();
                      return title.contains(_searchQuery) ||
                          category.contains(_searchQuery);
                    }).toList();

                    if (filteredProducts.isEmpty) {
                      return const Center(
                        child: Text(
                          'No products match your search.',
                          style: TextStyle(color: Color(0xFF10214B), fontSize: 16),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        String rawPrice =
                            (product['price']?.toString() ?? '0.00').replaceAll('₦', '').trim();
                        try {
                          double.parse(rawPrice);
                        } catch (e) {
                          rawPrice = '0.00';
                          debugPrint('Invalid price format for product ${product['title']}: $e');
                        }
                        Map<String, dynamic> extraFields = {};
                        if (product['extra_fields'] != null) {
                          try {
                            extraFields =
                                jsonDecode(product['extra_fields']) as Map<String, dynamic>;
                          } catch (e) {
                            debugPrint(
                                'Error decoding extra_fields for product ${product['title']}: $e');
                          }
                        }
                        return ProductCard(
                          productId: product['id']?.toString() ?? '',
                          sellerId: product['user_id']?.toString() ?? '',
                          imageUrl: product['image_url'] ?? 'https://via.placeholder.com/150',
                          productName: product['title'] ?? 'Unnamed Product',
                          productType: product['category'] ?? 'Unknown Category',
                          price: rawPrice,
                          phoneNumber: product['phone'] ?? '',
                          extraFields: extraFields,
                          description: product['product_description'] ?? 'No description',
                          location: product['location']?.toString() ?? 'Unknown Location',
                          businessName: product['name'] ?? 'Unknown Seller',
                          sellerAvatar:
                              product['seller_avatar'] ?? 'https://via.placeholder.com/150',
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String productId;
  final String sellerId;
  final String imageUrl;
  final String productName;
  final String productType;
  final String price;
  final String phoneNumber;
  final Map<String, dynamic> extraFields;
  final String description;
  final String location;
  final String businessName;
  final String sellerAvatar;

  const ProductCard({
    super.key,
    required this.productId,
    required this.sellerId,
    required this.imageUrl,
    required this.productName,
    required this.productType,
    required this.price,
    required this.phoneNumber,
    required this.extraFields,
    required this.description,
    required this.location,
    required this.businessName,
    required this.sellerAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint('Navigating to ProductDetailsScreen with location: $location');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productId: productId,
              sellerId: sellerId,
              name: productName,
              imageUrl: imageUrl,
              price: '₦$price',
              productType: productType,
              businessName: businessName,
              location: location,
              phoneNumber: phoneNumber,
              sellerAvatar: sellerAvatar,
              description: description,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image load error: $error, URL: $imageUrl');
                      return const Icon(
                        Icons.image_not_supported,
                        color: Color(0xFF10214B),
                        size: 50,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            productName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10214B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  productType,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10214B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 1,
                child: Text(
                  '₦$price',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10214B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: GestureDetector(
              onTap: () async {
                final url = Uri.parse('tel:$phoneNumber');
                try {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not launch phone dialer')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error launching dialer: $e')),
                    );
                  }
                  debugPrint('Dialer error: $e');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 65, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10214B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Contact Seller',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
