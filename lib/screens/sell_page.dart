import 'dart:io' show File, Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'main_screen.dart'; // Adjust based on your navigation
import 'package:wear_space/screens/notification_service.dart'; // Import NotificationService

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();

  // Controllers for category-specific fields
  final _sizeController = TextEditingController();
  final _materialController = TextEditingController();
  final _colorController = TextEditingController();
  final _lengthController = TextEditingController();
  final _wigTypeController = TextEditingController();
  final _brandController = TextEditingController();
  final _watchTypeController = TextEditingController();
  final _styleController = TextEditingController();
  final _typeController = TextEditingController();
  final _personalizationController = TextEditingController();
  final _certificationController = TextEditingController();
  final _conditionController = TextEditingController();
  final _genderController = TextEditingController();

  // Image picker variables
  XFile? _image;
  final _picker = ImagePicker();
  User? _user;
  bool _isSubmitting = false;
  final NotificationService _notificationService = NotificationService(); // Initialize NotificationService

  final List<String> _categories = [
    'Clothes',
    'Bag',
    'Wigs',
    'Shoes',
    'Watches',
    'Casual Wears',
    'Athleisure',
    'Jewelry',
    'Sustainable Apparel',
    'Accessories',
    'Underwear & Lingerie',
    'Outerwear',
    'Swimwear',
    'Formalwear',
    'Kids’ Fashion',
    'Vintage & Secondhand',
  ];

  // Define category-specific fields
  final Map<String, List<Map<String, dynamic>>> _categoryFields = {
    'Clothes': [
      {'label': 'Size', 'controller': null, 'type': 'text', 'required': true},
      {'label': 'Material', 'controller': null, 'type': 'text', 'required': false},
    ],
    'Bag': [
      {'label': 'Material', 'controller': null, 'type': 'text', 'required': true},
      {'label': 'Color', 'controller': null, 'type': 'text', 'required': false},
    ],
    'Wigs': [
      {'label': 'Length (inches)', 'controller': null, 'type': 'number', 'required': true},
      {
        'label': 'Type',
        'controller': null,
        'type': 'dropdown',
        'options': ['Synthetic', 'Human Hair'],
        'required': true
      },
    ],
    'Shoes': [
      {'label': 'Size', 'controller': null, 'type': 'number', 'required': true},
      {'label': 'Brand', 'controller': null, 'type': 'text', 'required': false},
    ],
    'Watches': [
      {'label': 'Brand', 'controller': null, 'type': 'text', 'required': true},
      {
        'label': 'Type',
        'controller': null,
        'type': 'dropdown',
        'options': ['Analog', 'Digital'],
        'required': true
      },
    ],
    'Casual Wears': [
      {'label': 'Size', 'controller': null, 'type': 'text', 'required': true},
      {
        'label': 'Style',
        'controller': null,
        'type': 'dropdown',
        'options': ['T-shirt', 'Jeans', 'Hoodie'],
        'required': true
      },
    ],
    'Athleisure': [
      {'label': 'Size', 'controller': null, 'type': 'text', 'required': true},
      {'label': 'Material', 'controller': null, 'type': 'text', 'required': true},
      {'label': 'Color', 'controller': null, 'type': 'text', 'required': false},
      {
        'label': 'Style',
        'controller': null,
        'type': 'dropdown',
        'options': ['Leggings', 'Sports Bra', 'Joggers', 'Yoga Pants'],
        'required': true
      },
    ],
    'Jewelry': [
      {
        'label': 'Type',
        'controller': null,
        'type': 'dropdown',
        'options': ['Necklace', 'Earring', 'Bracelet', 'Ring'],
        'required': true
      },
      {'label': 'Material', 'controller': null, 'type': 'text', 'required': true},
      {'label': 'Personalization', 'controller': null, 'type': 'text', 'required': false},
    ],
    'Sustainable Apparel': [
      {'label': 'Size', 'controller': null, 'type': 'text', 'required': true},
      {'label': 'Material', 'controller': null, 'type': 'text', 'required': true},
      {'label': 'Certification', 'controller': null, 'type': 'text', 'required': false},
    ],
    'Accessories': [
      {
        'label': 'Type',
        'controller': null,
        'type': 'dropdown',
        'options': ['Sunglasses', 'Hat', 'Scarf', 'Belt', 'Hair Accessory'],
        'required': true
      },
      {'label': 'Material', 'controller': null, 'type': 'text', 'required': true},
      {'label': 'Color', 'controller': null, 'type': 'text', 'required': false},
    ],
    'Underwear & Lingerie': [
      {'label': 'Size', 'controller': null, 'type': 'text', 'required': true},
      {
        'label': 'Type',
        'controller': null,
        'type': 'dropdown',
        'options': ['Bra', 'Panties', 'Shapewear', 'Sleepwear'],
        'required': true
      },
      {'label': 'Material', 'controller': null, 'type': 'text', 'required': false},
    ],
    'Outerwear': [
      {'label': 'Size', 'controller': null, 'type': 'text', 'required': true},
      {
        'label': 'Type',
        'controller': null,
        'type': 'dropdown',
        'options': ['Coat', 'Jacket', 'Blazer', 'Trench'],
        'required': true
      },
      {'label': 'Material', 'controller': null, 'type': 'text', 'required': true},
    ],
    'Swimwear': [
      {'label': 'Size', 'controller': null, 'type': 'text', 'required': true},
      {
        'label': 'Type',
        'controller': null,
        'type': 'dropdown',
        'options': ['Bikini', 'One-Piece', 'Cover-Up'],
        'required': true
      },
      {'label': 'Color', 'controller': null, 'type': 'text', 'required': false},
    ],
    'Formalwear': [
      {'label': 'Size', 'controller': null, 'type': 'text', 'required': true},
      {
        'label': 'Type',
        'controller': null,
        'type': 'dropdown',
        'options': ['Suit', 'Tuxedo', 'Evening Gown', 'Cocktail Dress'],
        'required': true
      },
      {'label': 'Material', 'controller': null, 'type': 'text', 'required': true},
    ],
    'Kids’ Fashion': [
      {'label': 'Size', 'controller': null, 'type': 'text', 'required': true},
      {
        'label': 'Type',
        'controller': null,
        'type': 'dropdown',
        'options': ['Clothing', 'Shoes', 'Accessories'],
        'required': true
      },
      {
        'label': 'Gender',
        'controller': null,
        'type': 'dropdown',
        'options': ['Boys', 'Girls', 'Unisex'],
        'required': false
      },
    ],
    'Vintage & Secondhand': [
      {'label': 'Size', 'controller': null, 'type': 'text', 'required': true},
      {
        'label': 'Condition',
        'controller': null,
        'type': 'dropdown',
        'options': ['Like New', 'Gently Used', 'Vintage'],
        'required': true
      },
      {'label': 'Brand', 'controller': null, 'type': 'text', 'required': false},
    ],
  };

  static const Map<String, String> productTableColumns = {
    'title': 'title',
    'category': 'category',
    'description': 'product_description',
    'location': 'location',
    'name': 'name',
    'phone': 'phone',
    'price': 'price',
    'image_url': 'image_url',
    'user_id': 'user_id',
    'created_at': 'created_at',
    'seller_avatar': 'seller_avatar',
    'extra_fields': 'extra_fields',
  };

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to use this feature.'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
      });
    }
    // Initialize NotificationService
    _notificationService.initialize();
    void assignController(String category, int index, TextEditingController controller) {
      if (_categoryFields.containsKey(category) && _categoryFields[category]!.length > index) {
        _categoryFields[category]![index]['controller'] = controller;
      }
    }
    assignController('Clothes', 0, _sizeController);
    assignController('Clothes', 1, _materialController);
    assignController('Bag', 0, _materialController);
    assignController('Bag', 1, _colorController);
    assignController('Wigs', 0, _lengthController);
    assignController('Wigs', 1, _wigTypeController);
    assignController('Shoes', 0, _sizeController);
    assignController('Shoes', 1, _brandController);
    assignController('Watches', 0, _brandController);
    assignController('Watches', 1, _watchTypeController);
    assignController('Casual Wears', 0, _sizeController);
    assignController('Casual Wears', 1, _styleController);
    assignController('Athleisure', 0, _sizeController);
    assignController('Athleisure', 1, _materialController);
    assignController('Athleisure', 2, _colorController);
    assignController('Athleisure', 3, _styleController);
    assignController('Jewelry', 0, _typeController);
    assignController('Jewelry', 1, _materialController);
    assignController('Jewelry', 2, _personalizationController);
    assignController('Sustainable Apparel', 0, _sizeController);
    assignController('Sustainable Apparel', 1, _materialController);
    assignController('Sustainable Apparel', 2, _certificationController);
    assignController('Accessories', 0, _typeController);
    assignController('Accessories', 1, _materialController);
    assignController('Accessories', 2, _colorController);
    assignController('Underwear & Lingerie', 0, _sizeController);
    assignController('Underwear & Lingerie', 1, _typeController);
    assignController('Underwear & Lingerie', 2, _materialController);
    assignController('Outerwear', 0, _sizeController);
    assignController('Outerwear', 1, _typeController);
    assignController('Outerwear', 2, _materialController);
    assignController('Swimwear', 0, _sizeController);
    assignController('Swimwear', 1, _typeController);
    assignController('Swimwear', 2, _colorController);
    assignController('Formalwear', 0, _sizeController);
    assignController('Formalwear', 1, _typeController);
    assignController('Formalwear', 2, _materialController);
    assignController('Kids’ Fashion', 0, _sizeController);
    assignController('Kids’ Fashion', 1, _typeController);
    assignController('Kids’ Fashion', 2, _genderController);
    assignController('Vintage & Secondhand', 0, _sizeController);
    assignController('Vintage & Secondhand', 1, _conditionController);
    assignController('Vintage & Secondhand', 2, _brandController);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _materialController.dispose();
    _colorController.dispose();
    _lengthController.dispose();
    _wigTypeController.dispose();
    _brandController.dispose();
    _watchTypeController.dispose();
    _styleController.dispose();
    _typeController.dispose();
    _personalizationController.dispose();
    _certificationController.dispose();
    _conditionController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        if (!mounted) return;
        if (pickedFile != null) {
          setState(() {
            _image = pickedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image selection cancelled or no image selected.')),
          );
        }
        return;
      }

      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        if (await Permission.storage.request().isGranted) {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
            withData: false,
          );
          if (!mounted) return;
          if (result != null && result.files.single.path != null) {
            final filePath = result.files.single.path!;
            setState(() {
              _image = XFile(filePath);
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image selection cancelled or no image selected.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission required for image selection.')),
          );
        }
        return;
      }

      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFF5F5F5),
          title: const Text('Select Image Source', style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Gallery', style: TextStyle(color: Colors.black54)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                title: const Text('Camera', style: TextStyle(color: Colors.black54)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF10214B))),
            ),
          ],
        ),
      );

      if (source == null || !mounted) return;

      PermissionStatus status;
      if (Platform.isAndroid) {
        status = source == ImageSource.gallery
            ? await Permission.photos.request()
            : await Permission.camera.request();
      } else if (Platform.isIOS) {
        status = source == ImageSource.gallery
            ? await Permission.photos.request()
            : await Permission.camera.request();
        if (status.isLimited && source == ImageSource.gallery) {
          status = PermissionStatus.granted;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image picking not supported on this platform.')),
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enable ${source == ImageSource.gallery ? 'photos' : 'camera'} permission in settings.',
            ),
            action: const SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: openAppSettings,
            ),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
        return;
      }

      if (status.isGranted || status.isLimited) {
        try {
          final pickedFile = await _picker.pickImage(
            source: source,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 85,
          );
          if (!mounted) return;
          if (pickedFile != null) {
            setState(() {
              _image = pickedFile;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image selection cancelled or no image selected.')),
            );
          }
        } catch (e) {
          debugPrint('Image picker error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to pick image. Try using a physical device.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied to access photos or camera.')),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
      debugPrint('Image picker error: $e\n$stackTrace');
    }
  }

  Future<String?> _uploadImage() async {
    if (_image == null || _user == null) {
      debugPrint('No image or user found');
      return null;
    }
    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        debugPrint('Starting image upload for user: ${_user!.id}, attempt ${attempt + 1}');
        final fileName = 'user-uploads/${_user!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        String imageUrl;
        if (kIsWeb) {
          debugPrint('Reading image bytes for web');
          final bytes = await _image!.readAsBytes();
          debugPrint('Image size: ${bytes.length} bytes');
          await Supabase.instance.client.storage.from('user-uploads').uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );
          imageUrl = Supabase.instance.client.storage.from('user-uploads').getPublicUrl(fileName);
        } else {
          debugPrint('Reading image file for non-web: ${_image!.path}');
          final file = File(_image!.path);
          await Supabase.instance.client.storage.from('user-uploads').upload(
                fileName,
                file,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );
          imageUrl = Supabase.instance.client.storage.from('user-uploads').getPublicUrl(fileName);
        }
        debugPrint('Image uploaded successfully: $imageUrl');
        return imageUrl;
      } catch (e, stackTrace) {
        attempt++;
        debugPrint('Image upload error (retry $attempt): $e, StackTrace: $stackTrace');
        if (attempt == maxRetries) {
          debugPrint('Image upload failed after $maxRetries retries');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image: $e')),
            );
          }
          return null;
        }
        debugPrint('Retrying upload...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    setState(() { _isSubmitting = true; });
    debugPrint('Starting _submitForm');
    try {
      if (_user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to post products.'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
        debugPrint('User not logged in');
        return;
      }

      // Validate main form fields
      debugPrint('Validating main form fields');
      debugPrint('Description value: "${_descriptionController.text.trim()}"');
      if (_titleController.text.trim().isEmpty ||
          _categoryController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty ||
          _locationController.text.trim().isEmpty ||
          _nameController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty ||
          _priceController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all required fields.'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
        debugPrint('Validation failed: Missing required fields');
        setState(() { _isSubmitting = false; });
        return;
      }

      // Validate category
      final selectedCategory = _categoryController.text.trim();
      if (!_categories.contains(selectedCategory)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid category selected.'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
        debugPrint('Validation failed: Invalid category $selectedCategory');
        setState(() { _isSubmitting = false; });
        return;
      }

      // Validate text for fashion-related content
      const nonFashionKeywords = ['phone', 'laptop', 'computer', 'electronics', 'car', 'gadget', 'appliance'];
      const fashionKeywords = [
        'dress', 'shirt', 'pants', 'jacket', 'shoes', 'bag', 'wig', 'watch', 'jeans', 'hoodie',
        'leggings', 'sports bra', 'joggers', 'yoga pants', 'necklace', 'earring', 'bracelet', 'ring',
        'organic cotton', 'recycled polyester', 'vegan leather', 'sunglasses', 'hat', 'scarf', 'belt',
        'hair accessory', 'bra', 'panties', 'shapewear', 'sleepwear', 'coat', 'blazer', 'trench',
        'bikini', 'one-piece', 'cover-up', 'suit', 'tuxedo', 'gown', 'cocktail dress', 'kids clothing',
        'vintage', 'secondhand'
      ];
      final textToCheck = '${_titleController.text.trim()} ${_descriptionController.text.trim()}'.toLowerCase();
      if (nonFashionKeywords.any((keyword) => textToCheck.contains(keyword))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product must be fashion-related. Avoid terms like electronics, cars, etc.'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
        debugPrint('Validation failed: Non-fashion keywords detected');
        setState(() { _isSubmitting = false; });
        return;
      }
      if (!fashionKeywords.any((keyword) => textToCheck.contains(keyword))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please include fashion-related terms like dress, necklace, or leggings.'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
        debugPrint('Validation failed: No fashion keywords detected');
        setState(() { _isSubmitting = false; });
        return;
      }

      // Validate category-specific fields
      debugPrint('Validating category-specific fields');
      bool isValid = true;
      final fields = _categoryFields[selectedCategory] ?? [];
      Map<String, String> extraFields = {};
      for (var field in fields) {
        final controller = field['controller'] as TextEditingController?;
        if (controller == null) continue;
        if (field['required'] == true && controller.text.trim().isEmpty) {
          isValid = false;
          break;
        }
        extraFields[field['label']] = controller.text.trim();
      }

      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all required category-specific fields.'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
        debugPrint('Validation failed: Missing required category-specific fields');
        setState(() { _isSubmitting = false; });
        return;
      }

      final price = double.tryParse(_priceController.text.trim());
      if (price == null || price <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid price (e.g., 19.99).'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
        debugPrint('Validation failed: Invalid price');
        setState(() { _isSubmitting = false; });
        return;
      }

      debugPrint('Uploading image');
      final imageUrl = await _uploadImage();
      // Continue even if image upload fails
      if (imageUrl == null) {
        debugPrint('Image upload failed, proceeding with default image URL');
      }

      // Fetch user profile picture with error handling
      debugPrint('Fetching user profile picture for user ID: ${_user!.id}');
      String sellerAvatar = 'https://via.placeholder.com/150'; // Default avatar
      try {
        final userDataList = await Supabase.instance.client
            .from('users')
            .select('profile_image_url')
            .eq('id', _user!.id);
        if (userDataList.isNotEmpty) {
          sellerAvatar = userDataList[0]['profile_image_url'] ?? sellerAvatar;
        } else {
          debugPrint('No user record found for ID: ${_user!.id}, using default avatar');
        }
      } catch (e, stackTrace) {
        debugPrint('Error fetching profile picture: $e, StackTrace: $stackTrace');
        debugPrint('Using default avatar URL: $sellerAvatar');
      }

      debugPrint('Seller avatar URL: $sellerAvatar');
      debugPrint('Saving product to Supabase');
      final productData = {
        productTableColumns['title']!: _titleController.text.trim(),
        productTableColumns['category']!: _categoryController.text.trim(),
        productTableColumns['description']!: _descriptionController.text.trim().isEmpty
            ? 'No description'
            : _descriptionController.text.trim(),
        productTableColumns['location']!: _locationController.text.trim(),
        productTableColumns['name']!: _nameController.text.trim(),
        productTableColumns['phone']!: _phoneController.text.trim(),
        productTableColumns['price']!: price,
        productTableColumns['image_url']!: imageUrl ?? 'https://via.placeholder.com/150', // Default image if upload fails
        productTableColumns['user_id']!: _user!.id,
        productTableColumns['created_at']!: DateTime.now().toIso8601String(),
        productTableColumns['seller_avatar']!: sellerAvatar,
        productTableColumns['extra_fields']!: jsonEncode(extraFields),
        'needs_review': false, // For moderation
      };
      debugPrint('Product data to be inserted: ${jsonEncode(productData)}');

      await Supabase.instance.client.from('products').insert(productData).catchError((e, stackTrace) {
        debugPrint('Supabase write error: $e, Data sent: ${jsonEncode(productData)}, StackTrace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Database error: $e'),
              backgroundColor: const Color(0xFF10214B),
            ),
          );
        }
        throw e;
      });

      // Send notification with product title
      try {
        await _notificationService.showNotification(
          'Product Posted',
          'Your product "${_titleController.text.trim()}" has been posted successfully!',
        );
        debugPrint('Notification sent for product: ${_titleController.text.trim()}');
      } catch (e) {
        debugPrint('Failed to send notification: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send notification: $e'),
              backgroundColor: const Color(0xFF10214B),
            ),
          );
        }
      }

      if (mounted) {
        debugPrint('Clearing form');
        _titleController.clear();
        _categoryController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _nameController.clear();
        _phoneController.clear();
        _priceController.clear();
        _sizeController.clear();
        _materialController.clear();
        _colorController.clear();
        _lengthController.clear();
        _wigTypeController.clear();
        _brandController.clear();
        _watchTypeController.clear();
        _styleController.clear();
        _typeController.clear();
        _personalizationController.clear();
        _certificationController.clear();
        _conditionController.clear();
        _genderController.clear();
        setState(() {
          _image = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product posted successfully!'),
            backgroundColor: Color(0xFF10214B),
          ),
        );

        // Navigate to MainScreen (adjust as needed)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
      }
      debugPrint('Error saving product: $e, StackTrace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'Sell Product',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF10214B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image picker section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                child: _image == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.black54, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Tap to select an image',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      )
                    : kIsWeb
                        ? FutureBuilder<Uint8List>(
                            future: _image!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to load image preview.')),
                                );
                                return const Center(
                                  child: Icon(Icons.error, color: Colors.red, size: 40),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Image preview error: $error');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to display image preview.')),
                                  );
                                  return const Icon(Icons.error, color: Colors.red, size: 40);
                                },
                              );
                            },
                          )
                        : Image.file(
                            File(_image!.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Image preview error: $error');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to display image preview.')),
                              );
                              return const Icon(Icons.error, color: Colors.red, size: 40);
                            },
                          ),
              ),
            ),
            const SizedBox(height: 16),
            // Form fields
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Product Title *',
                labelStyle: const TextStyle(color: Color(0xFF10214B)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoryController.text.isEmpty ? null : _categoryController.text,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category, style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _categoryController.text = value ?? '';
                });
              },
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Category *',
                labelStyle: const TextStyle(color: Color(0xFF10214B)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
              ),
              dropdownColor: const Color(0xFFF5F5F5),
            ),
            const SizedBox(height: 12),
            // Category-specific fields
            if (_categoryController.text.isNotEmpty &&
                _categoryFields.containsKey(_categoryController.text))
              ..._categoryFields[_categoryController.text]!.map((field) {
                if (field['type'] == 'dropdown') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      value: field['controller'].text.isEmpty ? null : field['controller'].text,
                      items: (field['options'] as List<String>).map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option, style: const TextStyle(color: Colors.black)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          field['controller'].text = value ?? '';
                        });
                      },
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: '${field['label']} ${field['required'] ? '*' : ''}',
                        labelStyle: const TextStyle(color: Color(0xFF10214B)),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF10214B),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF10214B),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF10214B),
                            width: 1.5,
                          ),
                        ),
                      ),
                      dropdownColor: const Color(0xFFF5F5F5),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: field['controller'],
                    keyboardType: field['type'] == 'number' ? TextInputType.number : TextInputType.text,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: '${field['label']} ${field['required'] ? '*' : ''}',
                      labelStyle: const TextStyle(color: Color(0xFF10214B)),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF10214B),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF10214B),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF10214B),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.black),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description *',
                labelStyle: const TextStyle(color: Color(0xFF10214B)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Location *',
                labelStyle: const TextStyle(color: Color(0xFF10214B)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Your Name *',
                labelStyle: const TextStyle(color: Color(0xFF10214B)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                labelStyle: const TextStyle(color: Color(0xFF10214B)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (₦) *',
                labelStyle: const TextStyle(color: Color(0xFF10214B)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10214B),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10214B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  _isSubmitting ? 'Submitting...' : 'Post Ad',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}