import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badges/badges.dart' as badges;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wear_space/screens/notifications_page.dart' as notifications_page;
import 'package:wear_space/screens/notification_service.dart' as notification_service;
import 'package:wear_space/screens/product_detail_screen.dart';
import 'package:wear_space/screens/payment_gateway_page.dart';
import 'package:wear_space/screens/product_listing_page.dart';
import 'package:wear_space/screens/search_page.dart';
import 'package:wear_space/screens/login_screen.dart';
import 'package:wear_space/screens/chat_page.dart';
import 'package:wear_space/screens/chat_list_page.dart';
import 'package:wear_space/screens/profile_page.dart';

// _MemoryCache remains unchanged
class _MemoryCache {
  static List<Map<String, dynamic>>? products;
  static DateTime? lastUpdated;
  static const _boxName = 'productsBox';
  static const _productsKey = 'products';
  static const _lastUpdatedKey = 'lastUpdated';
  static const Duration _cacheExpiry = Duration(hours: 24);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    await loadFromDisk();
  }

  static Future<void> loadFromDisk() async {
    final box = Hive.box(_boxName);
    final raw = box.get(_productsKey);
    final ts = box.get(_lastUpdatedKey);
    if (raw != null) {
      try {
        products = List<Map<String, dynamic>>.from(raw);
      } catch (e) {
        debugPrint('Cache load error: $e');
        products = <Map<String, dynamic>>[];
      }
    }
    if (ts != null) {
      lastUpdated = DateTime.tryParse(ts);
      if (lastUpdated != null && DateTime.now().difference(lastUpdated!) > _cacheExpiry) {
        products = <Map<String, dynamic>>[];
        await box.delete(_productsKey);
        await box.delete(_lastUpdatedKey);
      }
    }
  }

  static Future<void> saveToDisk() async {
    final box = Hive.box(_boxName);
    await box.put(_productsKey, products ?? []);
    await box.put(_lastUpdatedKey, lastUpdated?.toIso8601String());
  }

  static Future<void> clear() async {
    final box = Hive.box(_boxName);
    await box.delete(_productsKey);
    await box.delete(_lastUpdatedKey);
    products = null;
    lastUpdated = null;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _balanceVisible = true;
  double? _balance;
  String _selectedCategory = 'Explore';
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _viewProducts = [];
  bool _isLoading = false;
  bool _isManualRefreshing = false;
  String _searchQuery = '';
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }
    await _initCacheAndAttachStream();
    await _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('users')
            .select('balance')
            .eq('id', user.id)
            .maybeSingle();
        if (response != null && mounted) {
          setState(() {
            _balance = (response['balance'] as num?)?.toDouble() ?? 0.0; // Removed hardcoded 58240.75
          });
        } else {
          setState(() {
            _balance = 0.0; // Default to 0 if no data
          });
          debugPrint('No balance data found for user ${user.id}');
        }
      }
    } catch (e) {
      debugPrint('Error loading balance: $e');
      if (mounted) {
        setState(() {
          _balance = 0.0; // Default to 0 on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading balance: $e'), backgroundColor: const Color(0xFF10214B)),
        );
      }
    }
  }

  Future<void> _initCacheAndAttachStream() async {
    setState(() => _isLoading = true);
    try {
      await _MemoryCache.init();
      if (mounted) {
        setState(() {
          _viewProducts = _MemoryCache.products ?? <Map<String, dynamic>>[];
          _isLoading = _viewProducts.isEmpty;
        });
      }
      _attachStream();
    } catch (e) {
      debugPrint('Cache init error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cache: $e'), backgroundColor: const Color(0xFF10214B)),
        );
      }
    }
  }

  void _attachStream() {
    _sub?.cancel();
    _sub = _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: false)
        .listen((data) async {
          try {
            _MemoryCache.products = List<Map<String, dynamic>>.from(data);
            _MemoryCache.lastUpdated = DateTime.now();
            await _MemoryCache.saveToDisk();
            if (mounted) {
              setState(() {
                _viewProducts = _MemoryCache.products ?? <Map<String, dynamic>>[];
                _isLoading = false;
              });
            }
          } catch (e) {
            debugPrint('Stream data error: $e');
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error syncing products: $e'), backgroundColor: const Color(0xFF10214B)),
              );
            }
          }
        }, onError: (e) {
          debugPrint('Supabase stream error: $e');
          if (mounted) {
            setState(() => _isLoading = false);
            if (_viewProducts.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading products: $e'), backgroundColor: const Color(0xFF10214B)),
              );
            }
          }
        }, onDone: () {
          debugPrint('Supabase stream done');
          if (mounted) setState(() => _isLoading = false);
        });
  }

  Future<void> _manualRefresh() async {
    setState(() => _isManualRefreshing = true);
    try {
      final res = await _supabase
          .from('products')
          .select('*')
          .order('timestamp', ascending: false);
      _MemoryCache.products = List<Map<String, dynamic>>.from(res);
      _MemoryCache.lastUpdated = DateTime.now();
      await _MemoryCache.saveToDisk();
      if (mounted) {
        setState(() {
          _viewProducts = _MemoryCache.products ?? <Map<String, dynamic>>[];
          _isManualRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('Manual refresh error: $e');
      if (mounted) {
        setState(() => _isManualRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: $e'), backgroundColor: const Color(0xFF10214B)),
        );
      }
    }
  }

  void _onNavBarTap(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatListPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage()),
        );
        break;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final bool showLoading = _isLoading || _isManualRefreshing;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _manualRefresh,
        color: const Color(0xFF10214B),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _AppBarWithSearchDelegate(
                topPadding: topPadding,
                balanceVisible: _balanceVisible,
                balance: _balance ?? 0.0, // Removed hardcoded 58240.75
                onBalanceTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentGatewayPage()),
                  );
                  await _loadBalance(); // Refresh balance after returning
                },
                onSearchTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchPage(products: _viewProducts),
                    ),
                  );
                },
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                if (showLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: LinearProgressIndicator(
                      color: Color(0xFF10214B),
                      backgroundColor: Color(0xFF2DD4BF),
                    ),
                  ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'How May We Help You Today?',
                    style: TextStyle(
                      color: Color(0xFF10214B),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: BannerSlider(),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildContent(context, _viewProducts),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Map<String, dynamic>> products, {String? errorMessage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySection(context, products),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 32,
            height: (MediaQuery.of(context).size.width - 32) / 3.25,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/wearspace_banner 1.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Banner image load error: $error');
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
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10214B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10214B),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Wearspace is going global soon',
                      style: TextStyle(
                        color: Color(0xFF10214B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                _buildCountdownTimer(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        _buildProductsSection(context, products),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, List<Map<String, dynamic>> products) {
    final Map<String, Map<String, dynamic>> latestProductByCategory = {};
    for (final product in products) {
      final category = (product['category'] as String?)?.trim() ?? '';
      if (category.isEmpty) continue;
      final existing = latestProductByCategory[category];
      final ts = _parseTimestamp(product['timestamp']);
      final existingTs = existing != null ? _parseTimestamp(existing['timestamp']) : null;
      if (existing == null || (ts != null && existingTs != null && ts.isAfter(existingTs))) {
        latestProductByCategory[category] = product;
      }
    }

    final List<Map<String, dynamic>> latestProductsList = latestProductByCategory.values.toList()
      ..sort((a, b) {
        final aTs = _parseTimestamp(a['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTs = _parseTimestamp(b['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTs.compareTo(aTs);
      });

    if (latestProductsList.isEmpty) {
      return const Center(
        child: Text(
          'No categories available.',
          style: TextStyle(color: Color(0xFF10214B), fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Recent Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10214B),
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: latestProductsList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = latestProductsList[index];
              final categoryName = (p['category'] as String?) ?? 'Unknown';
              final imagePath = _getCategoryImage(categoryName);
              return CategoryCard(
                categoryName: categoryName,
                imagePath: imagePath,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductListingPage(categoryName: categoryName)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _getCategoryImage(String categoryName) {
    return 'assets/images/${categoryName.toUpperCase()}.jpg';
  }

  Widget _buildProductsSection(BuildContext context, List<Map<String, dynamic>> products) {
    final categories = ['Explore', ...products
        .map((product) => product['category'] as String?)
        .where((category) => category != null && category.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()..sort()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF10214B) : const Color(0xFF4B5563),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 2,
                        width: isSelected ? 30 : 0,
                        color: const Color(0xFF10214B),
                        margin: const EdgeInsets.only(top: 4),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10214B),
          ),
        ),
        const SizedBox(height: 16),
        _buildProductGrid(context, products),
      ],
    );
  }

  DateTime? _parseTimestamp(dynamic rawTs) {
    if (rawTs == null) return null;
    if (rawTs is DateTime) return rawTs;
    if (rawTs is String) return DateTime.tryParse(rawTs);
    if (rawTs is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawTs);
    }
    return null;
  }

  Widget _buildProductGrid(BuildContext context, List<Map<String, dynamic>> products) {
    var filteredProducts = _selectedCategory == 'Explore'
        ? products
        : products.where((product) => product['category'] == _selectedCategory).toList();

    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        final title = (product['title'] ?? '').toString().toLowerCase();
        final description = (product['product_description'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery.toLowerCase()) || description.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (filteredProducts.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty ? 'No products match your search.' : 'No products available.',
          style: const TextStyle(color: Color(0xFF10214B), fontSize: 16),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
        try {
          extraFields = product['extra_fields'] != null
              ? Map<String, dynamic>.from(product['extra_fields'] is String
                  ? jsonDecode(product['extra_fields'])
                  : product['extra_fields'])
              : {'name': product['name'] ?? 'Unknown Seller', 'location': product['location']?.toString() ?? 'Unknown Location'};
        } catch (e) {
          debugPrint('Error decoding extra_fields for product ${product['title']}: $e');
          extraFields = {'name': product['name'] ?? 'Unknown Seller', 'location': product['location']?.toString() ?? 'Unknown Location'};
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
    );
  }

  Widget _buildCountdownTimer() {
    final targetDate = DateTime.now().add(const Duration(days: 1));
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        final remaining = targetDate.difference(DateTime.now()).inSeconds;
        return remaining > 0 ? remaining : 0;
      }),
      initialData: targetDate.difference(DateTime.now()).inSeconds,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data! <= 0) {
          return const Text('Event Started!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10214B)));
        }
        final totalSeconds = snapshot.data!;
        final hours = totalSeconds ~/ 3600;
        final remainingSeconds = totalSeconds % 3600;
        final minutes = remainingSeconds ~/ 60;
        final seconds = remainingSeconds % 60;
        return Text(
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10214B)),
        );
      },
    );
  }
}

// Rest of the file (_AppBarWithSearchDelegate, ProductCard, CategoryCard, BannerSlider) remains unchanged
class _AppBarWithSearchDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final bool balanceVisible;
  final double balance;
  final VoidCallback onBalanceTap;
  final VoidCallback onSearchTap;

  _AppBarWithSearchDelegate({
    required this.topPadding,
    required this.balanceVisible,
    required this.balance,
    required this.onBalanceTap,
    required this.onSearchTap,
  });

  @override
  double get minExtent => kToolbarHeight + topPadding + 61;
  @override
  double get maxExtent => kToolbarHeight + topPadding + 61;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 28, 56, 128), Color(0xFF10214B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
            height: kToolbarHeight + topPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Wearspace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onBalanceTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              balanceVisible ? Icons.visibility : Icons.visibility_off,
                              size: 16,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              balanceVisible ? '₦${balance.toStringAsFixed(2)}' : '••••••',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<int>(
                      valueListenable: notification_service.NotificationService().notificationCount,
                      builder: (context, count, child) {
                        return badges.Badge(
                          showBadge: count > 0,
                          badgeContent: Text(
                            count.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                          badgeStyle: const badges.BadgeStyle(
                            badgeColor: Colors.red,
                            padding: EdgeInsets.all(4),
                          ),
                          position: badges.BadgePosition.topEnd(top: 2, end: 2),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const notifications_page.NotificationsPage()),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF10214B),
                borderRadius: BorderRadius.circular(12),
              ),
              height: 45,
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    'Search item or store...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
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
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFF10214B))),
                    errorWidget: (context, url, error) {
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
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  return;
                }
                final chatId = user.id.compareTo(sellerId) < 0 ? '${user.id}_$sellerId' : '$sellerId${user.id}';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      contactName: extraFields['name'] ?? 'Seller',
                      chatId: chatId,
                      avatar: extraFields['seller_avatar'] ?? 'https://via.placeholder.com/100',
                    ),
                  ),
                );
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

class CategoryCard extends StatelessWidget {
  final String imagePath;
  final String categoryName;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.imagePath,
    required this.categoryName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Category image load error: $error, Path: $imagePath');
                      return const Icon(
                        Icons.category,
                        color: Color(0xFF10214B),
                        size: 36,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              categoryName.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10214B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  _BannerSliderState createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentSlide = 0;
  Timer? _timer;

  final List<String> _bannerImages = [
    'assets/images/carouselbanner1.png',
    'assets/images/carouselbanner2.png',
    'assets/images/carouselbanner3.png',
    'assets/images/carouselbanner4.png',
    'assets/images/carouselbanner5.png',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentSlide < _bannerImages.length - 1) {
        _currentSlide++;
      } else {
        _currentSlide = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentSlide,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width - 32;
    final double height = availableWidth / 3.25;

    return SizedBox(
      width: availableWidth,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10214B),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          clipBehavior: Clip.hardEdge,
          onPageChanged: (index) => setState(() => _currentSlide = index),
          itemCount: _bannerImages.length,
          itemBuilder: (_, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(
                _bannerImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Banner image load error: $error, Asset: ${_bannerImages[index]}');
                  return const Icon(
                    Icons.image_not_supported,
                    color: Colors.white,
                    size: 50,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}