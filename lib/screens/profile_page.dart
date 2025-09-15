import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wear_space/screens/login_screen.dart';
import 'package:wear_space/screens/hamburger_sidebar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String fullName = '';
  String phoneNumber = '';
  String email = '';
  String businessName = '';
  String whatsAppLink = '';
  String? profileImageUrl;
  XFile? _imageFile;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isDrawerOpen = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in'), backgroundColor: Color(0xFF10214B)),
        );
      }
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      setState(() {
        fullName = response?['full_name']?.toString() ?? user.userMetadata?['full_name']?.toString() ?? 'developer';
        email = response?['email']?.toString() ?? user.email?.toString() ?? 'developer@appsnipp.com';
        phoneNumber = response?['phone_number']?.toString() ?? '+91-8129999999';
        businessName = response?['business_name']?.toString() ?? 'Not provided';
        whatsAppLink = response?['whatsapp_link']?.toString() ?? 'Not provided';
        profileImageUrl = response?['profile_image_url']?.toString() ?? 'https://via.placeholder.com/150';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e'), backgroundColor: const Color(0xFF10214B)),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      ImageSource? source;
      if (!kIsWeb && !Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
        source = await showDialog<ImageSource>(
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
      }

      if (source == null && !kIsWeb && !Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

      PermissionStatus status;
      if (kIsWeb) {
        final pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        if (!mounted) return;
        if (pickedFile != null) {
          setState(() => _imageFile = pickedFile);
          final imageUrl = await _uploadImage(pickedFile);
          if (imageUrl != null) {
            setState(() => profileImageUrl = imageUrl);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.'), backgroundColor: Color(0xFF10214B)),
          );
        }
        return;
      }

      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (!mounted) return;
        if (result != null && result.files.single.path != null) {
          final pickedFile = XFile(result.files.single.path!);
          setState(() => _imageFile = pickedFile);
          final imageUrl = await _uploadImage(pickedFile);
          if (imageUrl != null) {
            setState(() => profileImageUrl = imageUrl);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.'), backgroundColor: Color(0xFF10214B)),
          );
        }
        return;
      }

      status = source == ImageSource.gallery
          ? await Permission.photos.request()
          : await Permission.camera.request();
      if (Platform.isIOS && status.isLimited && source == ImageSource.gallery) {
        status = PermissionStatus.granted;
      }

      if (!mounted) return;

      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enable ${source == ImageSource.gallery ? 'photos' : 'camera'} permission in settings.',
            ),
            backgroundColor: const Color(0xFF10214B),
            action: const SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: openAppSettings,
            ),
          ),
        );
        return;
      }

      if (status.isGranted || status.isLimited) {
        final pickedFile = await _picker.pickImage(
          source: source!,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        if (!mounted) return;
        if (pickedFile != null) {
          setState(() => _imageFile = pickedFile);
          final imageUrl = await _uploadImage(pickedFile);
          if (imageUrl != null) {
            setState(() => profileImageUrl = imageUrl);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.'), backgroundColor: Color(0xFF10214B)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied to access photos or camera.'), backgroundColor: Color(0xFF10214B)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: const Color(0xFF10214B)),
        );
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      setState(() => _isLoading = true);
      final fileName = 'profile-images/${user.id}/${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image size exceeds 5MB limit.'), backgroundColor: Color(0xFF10214B)),
            );
          }
          return null;
        }
        await Supabase.instance.client.storage.from('profile-images').uploadBinary(fileName, bytes);
      } else {
        final file = File(image.path);
        if (await file.length() > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image size exceeds 5MB limit.'), backgroundColor: Color(0xFF10214B)),
            );
          }
          return null;
        }
        await Supabase.instance.client.storage.from('profile-images').upload(fileName, file);
      }
      final imageUrl = Supabase.instance.client.storage.from('profile-images').getPublicUrl(fileName);
      await Supabase.instance.client
          .from('users')
          .upsert({
            'id': user.id,
            'profile_image_url': imageUrl,
          });
      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e'), backgroundColor: const Color(0xFF10214B)),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
              .from('users')
              .upsert({
                'id': user.id,
                'full_name': fullName,
                'phone_number': phoneNumber.isEmpty ? null : phoneNumber,
                'business_name': businessName.isEmpty ? null : businessName,
                'whatsapp_link': whatsAppLink.isEmpty ? null : whatsAppLink,
              });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Color(0xFF10214B)),
            );
            setState(() => _isEditing = false);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: const Color(0xFF10214B)),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields correctly.'), backgroundColor: Color(0xFF10214B)),
        );
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully!'), backgroundColor: Color(0xFF10214B)),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: $e'), backgroundColor: const Color(0xFF10214B)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleDrawer() {
    setState(() => _isDrawerOpen = !_isDrawerOpen);
  }

  void _closeDrawer() {
    if (_isDrawerOpen) {
      setState(() => _isDrawerOpen = false);
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF10214B), size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10214B))),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.black12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double headerHeight = MediaQuery.of(context).size.height * 0.4;
    final double overlap = 30.0;

    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          // Dark blue header background
          Container(
            height: headerHeight,
            width: double.infinity,
            color: const Color(0xFF10214B),
          ),
          // Profile image, name, and email
          Positioned(
            top: headerHeight * 0.12,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: profileImageUrl != null
                        ? CachedNetworkImageProvider(profileImageUrl!)
                        : const NetworkImage('https://via.placeholder.com/200') as ImageProvider,
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content with white background
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: headerHeight - overlap),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Info',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10214B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _isEditing
                            ? Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      initialValue: fullName,
                                      style: const TextStyle(color: Color(0xFF10214B)),
                                      decoration: const InputDecoration(
                                        labelText: 'Name',
                                        labelStyle: TextStyle(color: Color(0xFF10214B)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(8)),
                                        ),
                                        filled: true,
                                        fillColor: Color(0xFFF5F5F5),
                                      ),
                                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                                      onSaved: (value) => fullName = value!,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: DropdownButtonFormField<String>(
                                            value: phoneNumber.startsWith('+') ? phoneNumber.substring(0, phoneNumber.indexOf('-') + 1) : '+91-',
                                            items: ['+1-', '+91-', '+44-', '+33-'].map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  phoneNumber = newValue + (phoneNumber.contains('-') ? phoneNumber.substring(phoneNumber.indexOf('-') + 1) : '');
                                                });
                                              }
                                            },
                                            decoration: const InputDecoration(
                                              labelText: 'Code',
                                              labelStyle: TextStyle(color: Color(0xFF10214B)),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                                              ),
                                              filled: true,
                                              fillColor: Color(0xFFF5F5F5),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: phoneNumber.contains('-') ? phoneNumber.substring(phoneNumber.indexOf('-') + 1) : phoneNumber,
                                            style: const TextStyle(color: Color(0xFF10214B)),
                                            decoration: const InputDecoration(
                                              labelText: 'Mobile',
                                              labelStyle: TextStyle(color: Color(0xFF10214B)),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                                              ),
                                              filled: true,
                                              fillColor: Color(0xFFF5F5F5),
                                            ),
                                            keyboardType: TextInputType.phone,
                                            validator: (value) {
                                              if (value!.isEmpty) return 'Please enter your phone number';
                                              if (!RegExp(r'^[\d\s-]{7,}$').hasMatch(value)) {
                                                return 'Please enter a valid phone number';
                                              }
                                              return null;
                                            },
                                            onSaved: (value) {
                                              final code = phoneNumber.substring(0, phoneNumber.indexOf('-') + 1);
                                              phoneNumber = code + (value ?? '');
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      initialValue: businessName == 'Not provided' ? '' : businessName,
                                      style: const TextStyle(color: Color(0xFF10214B)),
                                      decoration: const InputDecoration(
                                        labelText: 'Business Name',
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
                                      initialValue: whatsAppLink == 'Not provided' ? '' : whatsAppLink,
                                      style: const TextStyle(color: Color(0xFF10214B)),
                                      decoration: const InputDecoration(
                                        labelText: 'WhatsApp Link',
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
                                          return 'Please enter a valid WhatsApp link';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) => whatsAppLink = value ?? '',
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  _buildInfoRow(Icons.person_outline, 'Name', fullName),
                                  _buildInfoRow(Icons.phone_android, 'Mobile', phoneNumber),
                                  _buildInfoRow(Icons.email_outlined, 'Email', email),
                                  if (businessName != 'Not provided')
                                    _buildInfoRow(Icons.business, 'Business Name', businessName),
                                  if (whatsAppLink != 'Not provided')
                                    _buildInfoRow(Icons.link, 'WhatsApp Link', whatsAppLink),
                                ],
                              ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _isEditing ? _saveProfile() : setState(() => _isEditing = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10214B),
                              padding: const EdgeInsets.symmetric(horizontal: 160, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _isEditing ? 'Save Profile' : 'Edit Profile',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Menu button
          Positioned(
            top: 12,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 24),
              onPressed: _toggleDrawer,
              padding: EdgeInsets.zero,
            ),
          ),
          // Drawer overlay
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _closeDrawer,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.grey.withOpacity(0.3),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),
            ),
          // Sidebar drawer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: _isDrawerOpen ? MediaQuery.of(context).size.width * 0.2 : MediaQuery.of(context).size.width,
            top: 0.0,
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height,
            child: Container(
              color: Colors.white,
              child: HamburgerSidebar(),
            ),
          ),
        ],
      ),
    );
  }
}