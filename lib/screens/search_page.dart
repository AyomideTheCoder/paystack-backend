import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wear_space/screens/product_detail_screen.dart';
import 'dart:convert';

class SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> products;

  const SearchPage({super.key, required this.products});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  String query = "";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          query = searchController.text.toLowerCase();
        });
      });
    });
    // Request focus when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter products by search query only if query is not empty
    final filteredProducts = query.isNotEmpty
        ? widget.products.where((product) {
            final title = (product['title'] ?? '').toString().toLowerCase();
            final description = (product['product_description'] ?? '').toString().toLowerCase();
            return title.contains(query) || description.contains(query);
          }).toList()
        : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10214B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
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
            controller: searchController,
            focusNode: searchFocusNode,
            decoration: const InputDecoration(
              icon: Icon(Icons.search, color: Color(0xFF10214B)),
              hintText: 'Search for products...',
              hintStyle: TextStyle(color: Color(0xFF10214B)),
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Color(0xFF10214B)),
            onSubmitted: (_) {
              searchFocusNode.unfocus();
            },
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: query.isEmpty
          ? const SizedBox.shrink() // Empty body when no query
          : filteredProducts.isEmpty
              ? const Center(
                  child: Text(
                    'Sorry product is not available.',
                    style: TextStyle(
                      color: Color(0xFF10214B),
                      fontSize: 16,
                    ),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65,
                  children: filteredProducts.map((product) {
                    String rawPrice = (product['price']?.toString() ?? '0.00').replaceAll('₦', '').trim();
                    try {
                      double.parse(rawPrice);
                    } catch (e) {
                      rawPrice = '0.00';
                      debugPrint('Invalid price format for product ${product['title']}: $e');
                    }

                    Map<String, dynamic> extraFields = {};
                    if (product['extra_fields'] != null) {
                      try {
                        extraFields = jsonDecode(product['extra_fields']) as Map<String, dynamic>;
                      } catch (e) {
                        debugPrint('Error decoding extra_fields for product ${product['title']}: $e');
                        extraFields = {
                          'name': product['name'] ?? 'Unknown Seller',
                          'location': product['location']?.toString() ?? 'Unknown Location',
                        };
                      }
                    } else {
                      extraFields = {
                        'name': product['name'] ?? 'Unknown Seller',
                        'location': product['location']?.toString() ?? 'Unknown Location',
                      };
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
                      description: product['product_description'] ?? '',
                    );
                  }).toList(),
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
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
              businessName: extraFields['name'] ?? 'Unknown Seller',
              location: extraFields['location'] ?? '',
              phoneNumber: phoneNumber,
              sellerAvatar: extraFields['seller_avatar'] ?? 'https://via.placeholder.com/100',
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