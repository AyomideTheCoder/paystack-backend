import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'chat_page.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final String sellerId;
  final String name;
  final String imageUrl;
  final String price;
  final String productType;
  final String businessName;
  final String location;
  final String phoneNumber;
  final String sellerAvatar;
  final String description;

  const ProductDetailsScreen({
    super.key,
    this.productId = '',
    this.sellerId = '',
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.productType,
    required this.businessName,
    required this.location,
    required this.phoneNumber,
    required this.sellerAvatar,
    required this.description,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String _sellerAvatar = 'https://via.placeholder.com/150';
  String _businessName = 'Unknown Seller';
  String _description = '';
  String _location = '';
  String _imageUrl = '';
  String _phoneNumber = '';
  String _price = '';
  String _name = '';
  String _productType = '';
  bool _isLoading = true;
  bool _isInWishlist = false;
  bool _isContacting = false; // New state for contact button

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _imageUrl = widget.imageUrl;
    _price = widget.price;
    _productType = widget.productType;
    _description = widget.description;
    _location = widget.location;
    _phoneNumber = widget.phoneNumber;
    _businessName = widget.businessName;
    _sellerAvatar = widget.sellerAvatar;
    _loadData();
    _checkWishlistStatus();
  }

  Future<void> _loadData() async {
    try {
      if (widget.productId.isNotEmpty) {
        final productResponse = await Supabase.instance.client
            .from('products')
            .select()
            .eq('id', widget.productId)
            .maybeSingle();

        if (productResponse != null && mounted) {
          setState(() {
            _name = productResponse['title'] ?? _name;
            _productType = productResponse['category'] ?? _productType;
            _price = productResponse['price']?.toString() ?? _price;
            _phoneNumber = productResponse['phone'] ?? _phoneNumber;
            _description = productResponse['product_description']?.isNotEmpty == true
                ? productResponse['product_description']
                : _description.isNotEmpty
                    ? _description
                    : 'No description provided.';
            _location = productResponse['location']?.isNotEmpty == true
                ? productResponse['location']
                : _location.isNotEmpty
                    ? _location
                    : 'No location provided.';
            _imageUrl = productResponse['image_url']?.isNotEmpty == true
                ? productResponse['image_url']
                : _imageUrl;
          });
        }
      }

      if (widget.sellerId.isNotEmpty) {
        final sellerResponse = await Supabase.instance.client
            .from('users')
            .select('full_name, profile_image_url')
            .eq('id', widget.sellerId)
            .maybeSingle();

        if (sellerResponse != null && mounted) {
          setState(() {
            _businessName = sellerResponse['full_name']?.isNotEmpty == true
                ? sellerResponse['full_name']
                : _businessName;
            _sellerAvatar = sellerResponse['profile_image_url']?.isNotEmpty == true
                ? sellerResponse['profile_image_url']
                : _sellerAvatar;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product details: $e'),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkWishlistStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || widget.productId.isEmpty) return;

    try {
      final existing = await Supabase.instance.client
          .from('wishlist')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', widget.productId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isInWishlist = existing != null;
        });
      }
    } catch (e) {
      debugPrint('Error checking wishlist status: $e');
    }
  }

  Future<void> _toggleWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to manage your wishlist'),
            backgroundColor: Color(0xFF10214B),
          ),
        );
      }
      return;
    }

    if (widget.productId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product ID not available'),
            backgroundColor: Color(0xFF10214B),
          ),
        );
      }
      return;
    }

    try {
      if (_isInWishlist) {
        await Supabase.instance.client
            .from('wishlist')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', widget.productId);

        if (mounted) {
          setState(() {
            _isInWishlist = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from wishlist'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
      } else {
        await Supabase.instance.client.from('wishlist').insert({
          'user_id': user.id,
          'product_id': widget.productId,
          'created_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          setState(() {
            _isInWishlist = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to wishlist'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Wishlist error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating wishlist: $e'),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
      }
    }
  }

  void _showFullImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: _imageUrl.isNotEmpty
                ? Image.network(
                    _imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image load error (network): $error');
                      return const Icon(Icons.image_not_supported, size: 100, color: Color(0xFF10214B));
                    },
                  )
                : const Icon(Icons.image_not_supported, size: 100, color: Color(0xFF10214B)),
          ),
        ),
      ),
    );
  }

  Future<String?> _getOrCreateChatId() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || widget.sellerId.isEmpty) {
      debugPrint('No current user or seller ID: user=${currentUser?.id}, sellerId=${widget.sellerId}');
      return null;
    }

    final currentUserId = currentUser.id;

    try {
      // Optimized check for existing chat involving both users
      final existingChat = await Supabase.instance.client
          .from('chat_users')
          .select('chat_id')
          .eq('user_id', currentUserId)
          .inFilter('chat_id', await Supabase.instance.client
              .from('chat_users')
              .select('chat_id')
              .eq('user_id', widget.sellerId)
              .then((res) => res.map((e) => e['chat_id']).toList()))
          .maybeSingle();

      if (existingChat != null) {
        final chatId = existingChat['chat_id'] as String;
        debugPrint('Found existing chat: $chatId');
        return chatId;
      }

      // Create a new chat
      final newChat = await Supabase.instance.client.from('chats').insert({
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
        'name': _businessName,
        'avatar': _sellerAvatar,
        'message': null,
        'unread': 0,
        'phone': _phoneNumber,
        'email': '',
      }).select('id').maybeSingle();

      if (newChat == null) {
        debugPrint('Failed to create new chat');
        return null;
      }

      final newChatId = newChat['id'] as String;
      debugPrint('Created new chat: $newChatId');

      // Insert both users into chat_users table using upsert
      try {
        await Supabase.instance.client.from('chat_users').upsert([
          {'chat_id': newChatId, 'user_id': currentUserId},
          {'chat_id': newChatId, 'user_id': widget.sellerId},
        ], onConflict: 'chat_id,user_id');
      } catch (e) {
        debugPrint('Error inserting into chat_users: $e');
        // Clean up the chat if chat_users insert fails
        await Supabase.instance.client.from('chats').delete().eq('id', newChatId);
        return null;
      }

      // Insert initial message into messages table
      try {
        final initialMessage = {
          'id': const Uuid().v4(), // Use UUID for message ID
          'chat_id': newChatId,
          'user_id': currentUserId,
          'text': 'Hello! I’m interested in your product: $_name',
          'image_url': null,
          'time': DateTime.now().toIso8601String(),
          'is_sent_by_me': true,
          'is_read': false,
        };
        await Supabase.instance.client.from('messages').insert(initialMessage);
      } catch (e) {
        debugPrint('Error inserting initial message: $e');
        // Clean up chat and chat_users if message insert fails
        await Supabase.instance.client.from('chat_users').delete().eq('chat_id', newChatId);
        await Supabase.instance.client.from('chats').delete().eq('id', newChatId);
        return null;
      }

      return newChatId;
    } catch (e) {
      debugPrint('Error in _getOrCreateChatId: $e');
      return null;
    }
  }

  Future<void> _contactSeller() async {
    if (_isContacting) return; // Prevent multiple clicks
    setState(() => _isContacting = true);

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to send a message'),
            backgroundColor: Color(0xFF10214B),
          ),
        );
      }
      setState(() => _isContacting = false);
      return;
    }

    if (widget.sellerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller ID not available'),
            backgroundColor: Color(0xFF10214B),
          ),
        );
      }
      setState(() => _isContacting = false);
      return;
    }

    try {
      final chatId = await _getOrCreateChatId();
      if (chatId != null && mounted) {
        debugPrint('Navigating to ChatPage with chatId: $chatId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              contactName: _businessName,
              chatId: chatId,
              avatar: _sellerAvatar,
            ),
          ),
        );
      } else {
        debugPrint('Chat ID is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start chat'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _contactSeller: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isContacting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF10214B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isLoading ? 'Loading...' : _name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10214B),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10214B)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _showFullImage,
                      child: Container(
                        height: 320,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _imageUrl.isNotEmpty
                              ? Image.network(
                                  _imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('Image load error (network): $error');
                                    return const Icon(Icons.image_not_supported, size: 100, color: Color(0xFF10214B));
                                  },
                                )
                              : const Icon(Icons.image_not_supported, size: 100, color: Color(0xFF10214B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10214B),
                      ),
                    ),
                    Text(
                      _price,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: _sellerAvatar.isNotEmpty
                              ? Image.network(
                                  _sellerAvatar,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('Seller avatar load error: $error');
                                    return const Icon(Icons.person, size: 50, color: Color(0xFF10214B));
                                  },
                                )
                              : const Icon(Icons.person, size: 50, color: Color(0xFF10214B)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _businessName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10214B),
                              ),
                            ),
                            Text(
                              'Seller',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10214B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _description.isEmpty ? 'No description provided.' : _description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF10214B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10214B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _location.isEmpty ? 'No location provided.' : _location,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF10214B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10214B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _phoneNumber.isEmpty ? 'No contact provided.' : _phoneNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF10214B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _isContacting ? null : _contactSeller,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10214B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isContacting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Contact Seller',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                        ElevatedButton(
                          onPressed: _toggleWishlist,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isInWishlist ? Colors.grey : const Color(0xFF2DD4BF),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            _isInWishlist ? 'Remove from Wishlist' : 'Add to Wishlist',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}