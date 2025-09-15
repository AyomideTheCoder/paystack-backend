import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wear_space/screens/notification_service.dart'; // Import NotificationService

class SellerRegistrationPage extends StatefulWidget {
  const SellerRegistrationPage({super.key});

  @override
  State<SellerRegistrationPage> createState() => _SellerRegistrationPageState();
}

class _SellerRegistrationPageState extends State<SellerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  String fullName = '';
  String phoneNumber = '';
  String email = '';
  String businessName = '';
  String whatsAppLink = '';
  XFile? _imageFile;
  bool _isLoading = false;
  final _picker = ImagePicker();

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
            _imageFile = pickedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.')),
          );
        }
        return;
      }

      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (!mounted) return;
        if (result != null && result.files.single.path != null) {
          final filePath = result.files.single.path!;
          try {
            final file = File(filePath);
            if (await file.length() > 0) {
              final appDir = await getApplicationDocumentsDirectory();
              final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(filePath)}';
              final savedImage = await file.copy('${appDir.path}/$uniqueFileName');
              setState(() {
                _imageFile = XFile(savedImage.path);
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selected image file is empty or inaccessible.')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to access selected image.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.')),
          );
        }
        return;
      }

      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Select Image Source', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Gallery', style: TextStyle(color: Colors.white70)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                title: const Text('Camera', style: TextStyle(color: Colors.white70)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
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

      if (!mounted) return;

      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enable ${source == ImageSource.gallery ? 'photos' : 'camera'} permission in settings.',
            ),
            action: const SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
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
            final file = File(pickedFile.path);
            if (await file.length() > 0) {
              final appDir = await getApplicationDocumentsDirectory();
              final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(pickedFile.path)}';
              final savedImage = await file.copy('${appDir.path}/$uniqueFileName');
              setState(() {
                _imageFile = XFile(savedImage.path);
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selected image file is empty or inaccessible.')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No image selected.')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to pick image. Try again.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied to access photos or camera.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sellerFullName', fullName);
        await prefs.setString('sellerPhone', phoneNumber);
        await prefs.setString('sellerEmail', email);
        await prefs.setString('sellerBusinessName', businessName);
        await prefs.setString('sellerWhatsAppLink', whatsAppLink);
        if (_imageFile != null) {
          if (kIsWeb) {
            final bytes = await _imageFile!.readAsBytes();
            final imageBase64 = base64Encode(bytes);
            await prefs.setString('sellerPhotoBase64', imageBase64);
          } else {
            await prefs.setString('sellerPhotoPath', _imageFile!.path);
            final bytes = await _imageFile!.readAsBytes();
            final imageBase64 = base64Encode(bytes);
            await prefs.setString('sellerPhotoBase64', imageBase64);
          }
        }
        await prefs.setBool('isSellerRegistered', true);

        // Trigger notification for successful seller registration
        await NotificationService().showNotification(
          'Welcome to Naija Market',
          'Seller account created successfully for $fullName.',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $e')),
          );
        }
        debugPrint('Registration error: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields correctly.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'Register as Seller',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF10214B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFFFFFFF),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8ECEF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black26),
                          ),
                          child: _imageFile == null
                              ? const Icon(
                                  Icons.add_photo_alternate,
                                  color: Colors.black87,
                                  size: 40,
                                )
                              : kIsWeb
                                  ? Image.network(
                                      _imageFile!.path,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.black87,
                                          size: 40,
                                        );
                                      },
                                    )
                                  : Image.file(
                                      File(_imageFile!.path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.black87,
                                          size: 40,
                                        );
                                      },
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: Color(0xFF10214B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
                      onSaved: (value) => fullName = value!,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: Color(0xFF10214B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value!.isEmpty) return 'Please enter your phone number';
                        if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                      onSaved: (value) => phoneNumber = value!,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                        labelStyle: TextStyle(color: Color(0xFF10214B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      onSaved: (value) => email = value ?? '',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Business Name (optional)',
                        labelStyle: TextStyle(color: Color(0xFF10214B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      onSaved: (value) => businessName = value ?? '',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp Link (optional)',
                        labelStyle: TextStyle(color: Color(0xFF10214B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !RegExp(r'^https?://(wa\.me|api\.whatsapp\.com|chat\.whatsapp\.com)/.*$').hasMatch(value)) {
                          return 'Please enter a valid WhatsApp link (e.g., https://wa.me/...)';
                        }
                        return null;
                      },
                      onSaved: (value) => whatsAppLink = value ?? '',
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF10214B)))
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10214B),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: const Text(
                                'Register & Continue',
                                style: TextStyle(
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
            ),
          ),
        ],
      ),
    );
  }
}