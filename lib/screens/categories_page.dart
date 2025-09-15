import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wear_space/screens/product_listing_page.dart';
import 'package:wear_space/screens/uploaded_products_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Map<String, dynamic>> _cachedProducts = [];
  List<String> _cachedCategories = [];
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCacheInstantly();
    _fetchAndCacheCategories();

    // Preload images after first frame (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCacheInstantly() async {
    final box = await Hive.openBox('categories_cache');
    final cachedProducts = box.get('products', defaultValue: []);
    final cachedCategories = box.get('categories', defaultValue: []);

    if (cachedProducts is List && cachedCategories is List) {
      setState(() {
        _cachedProducts =
            List<Map<String, dynamic>>.from(cachedProducts.cast<Map>());
        _cachedCategories = List<String>.from(cachedCategories);
      });
    }
  }

  Future<void> _cacheProducts(List<Map<String, dynamic>> products) async {
    var box = await Hive.openBox('categories_cache');
    await box.put('products', products);
    final categories = products
        .map((doc) => doc['category'] as String?)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
    await box.put('categories', categories);
  }

  Future<List<String>> _fetchCategories() async {
    try {
      final response =
          await Supabase.instance.client.rpc('get_distinct_categories');
      return (response as List<dynamic>).cast<String>();
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<void> _fetchAndCacheCategories() async {
    try {
      final categories = await _fetchCategories();
      var box = await Hive.openBox('categories_cache');
      await box.put('categories', categories);
      setState(() {
        _cachedCategories = categories;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _preloadImages() async {
    final possibleCategories = ['shoes', 'clothing', 'accessories'];
    for (var category in possibleCategories) {
      final imagePath = _getCategoryImage(category);
      await precacheImage(AssetImage(imagePath), context);
    }
  }

  String _getCategoryImage(String categoryName) {
    final formatted = categoryName.toUpperCase();
    return "assets/images/$formatted.jpg";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10214B),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderBar(
              maxHeight: 60,
              child: Container(
                color: const Color(0xFF10214B),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Shop',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UploadedProductsPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'YOUR PRODUCTS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderBar(
              maxHeight: 80,
              child: Container(
                color: const Color(0xFF10214B),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search your categories',
                        hintStyle: const TextStyle(color: Color(0xFF10214B)),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF10214B)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Color(0xFF10214B)),
                      onChanged: (value) {
                        _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          setState(() {
                            _searchQuery = value.trim().toLowerCase();
                          });
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                top: false,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('products')
                      .stream(primaryKey: ['id'])
                      .order('timestamp', ascending: false)
                      .limit(50),
                  initialData: _cachedProducts, // 🚀 show cache instantly
                  builder: (context, snapshot) {
                    List<String> categories = _cachedCategories;
                    List<Map<String, dynamic>> products = _cachedProducts;

                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      products = snapshot.data!;
                      _cacheProducts(products);
                      categories = products
                          .map((doc) => doc['category'] as String?)
                          .where((c) => c != null && c.isNotEmpty)
                          .cast<String>()
                          .toSet()
                          .toList()
                        ..sort();
                    }

                    final filteredCategories = categories
                        .where((cat) =>
                            cat.toLowerCase().contains(_searchQuery))
                        .toList();

                    if (filteredCategories.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No categories found.',
                            style: TextStyle(
                              color: Color(0xFF10214B),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
                            child: Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10214B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.65,
                              ),
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                return _buildCategoryItem(
                                    context, filteredCategories[index], products);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
      BuildContext context, String title, List<Map<String, dynamic>> products) {
    final productCount =
        products.where((doc) => doc['category'] == title).length;
    final defaultImage = _getCategoryImage(title);

    return GestureDetector(
      onTap: () {
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductListingPage(categoryName: title),
            ),
          );
        } catch (e) {
          debugPrint('Navigation error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error navigating to product listing'),
            ),
          );
        }
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
                  child: Image.asset(
                    defaultImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.category,
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
            title.toUpperCase(),
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
                  '$productCount item${productCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10214B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                flex: 1,
                child: Text(
                  'Category',
                  style: TextStyle(
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
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 65, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10214B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'View Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBar extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double maxHeight;

  _HeaderBar({required this.child, required this.maxHeight});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: maxHeight, child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => maxHeight;

  @override
  bool shouldRebuild(covariant _HeaderBar oldDelegate) {
    return child != oldDelegate.child || maxHeight != oldDelegate.maxHeight;
  }
}
