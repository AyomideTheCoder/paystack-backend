import 'dart:io';
import 'dart:ui' as ui;
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'chat_page.dart';
import 'profile_page.dart';

class Chat {
  final String id;
  final String name;
  final String? message;
  final DateTime time;
  final String avatar;
  final int unread;
  final String phone;
  final String email;

  Chat({
    required this.id,
    required this.name,
    this.message,
    required this.time,
    required this.avatar,
    required this.unread,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'message': message,
      'created_at': time.toIso8601String(),
      'avatar': avatar,
      'unread': unread,
      'phone': phone,
      'email': email,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    print('Raw chat data: $map'); // Debug
    return Chat(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      message: map['last_message']?.toString(),
      time: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      avatar: map['avatar']?.toString() ?? 'https://via.placeholder.com/100',
      unread: (map['unread'] is num ? map['unread'].toInt() : map['unread']) ?? 0,
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
    );
  }
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newChatNameController = TextEditingController();
  final TextEditingController _newChatPhoneController = TextEditingController();
  final TextEditingController _newChatEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _uploadingImageId;
  XFile? _selectedImage;

  @override
  void dispose() {
    _searchController.dispose();
    _newChatNameController.dispose();
    _newChatPhoneController.dispose();
    _newChatEmailController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No authenticated user found.'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
        return null;
      }
      setState(() => _uploadingImageId = '${user.id}_${DateTime.now().millisecondsSinceEpoch}');
      final fileName = 'chat_avatars/${user.id}/${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size exceeds 5MB limit.'),
                backgroundColor: Color(0xFF10214B),
              ),
            );
          }
          setState(() => _uploadingImageId = null);
          return null;
        }
        await Supabase.instance.client.storage.from('chat_avatars').uploadBinary(fileName, bytes);
      } else {
        final file = File(image.path);
        if (await file.length() > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size exceeds 5MB limit.'),
                backgroundColor: Color(0xFF10214B),
              ),
            );
          }
          setState(() => _uploadingImageId = null);
          return null;
        }
        await Supabase.instance.client.storage.from('chat_avatars').upload(fileName, file);
      }
      final imageUrl = Supabase.instance.client.storage.from('chat_avatars').getPublicUrl(fileName);
      setState(() => _uploadingImageId = null);
      return imageUrl;
    } catch (e) {
      setState(() => _uploadingImageId = null);
      if (mounted) {
        String errorMessage = 'Error uploading image: $e';
        if (e.toString().contains('bucket not found')) {
          errorMessage = 'Storage bucket "chat_avatars" not found. Please contact support.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Color(0xFF10214B),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo permission denied.'),
                backgroundColor: Color(0xFF10214B),
              ),
            );
          }
          return;
        }
      }
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      print('Picked file: ${pickedFile?.path}'); // Debug
      if (pickedFile != null && mounted) {
        setState(() => _selectedImage = pickedFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _selectedImage = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Color(0xFF10214B),
          ),
        );
      }
    }
  }

  Future<void> _createNewChat() async {
    _selectedImage = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add New Contact',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10214B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        await _pickImage();
                        setModalState(() {});
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _selectedImage == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
                                  Text('Add Photo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              )
                            : Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  kIsWeb
                                      ? Image.network(
                                          _selectedImage!.path,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.error,
                                            color: Color(0xFF10214B),
                                            size: 40,
                                          ),
                                        )
                                      : Image.file(
                                          File(_selectedImage!.path),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.error,
                                            color: Color(0xFF10214B),
                                            size: 40,
                                          ),
                                        ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Color(0xFF10214B), size: 20),
                                    onPressed: () => setModalState(() => _selectedImage = null),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newChatNameController,
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10214B)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10214B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10214B), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter a full name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newChatPhoneController,
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10214B)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10214B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10214B), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => (value?.isEmpty ?? true) || !RegExp(r'^\+?[\d\s-]{7,15}$').hasMatch(value!)
                          ? 'Invalid phone number format'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newChatEmailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10214B)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10214B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10214B), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value != null && value.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)
                          ? 'Invalid email format'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _newChatNameController.clear();
                            _newChatPhoneController.clear();
                            _newChatEmailController.clear();
                            setModalState(() => _selectedImage = null);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10214B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null // Disable button when loading
                              : () async {
                                  if (_formKey.currentState!.validate() && Supabase.instance.client.auth.currentUser != null) {
                                    setModalState(() => _isLoading = true); // Set loading state
                                    final userId = Supabase.instance.client.auth.currentUser!.id;
                                    String? avatarUrl = 'https://via.placeholder.com/100';
                                    if (_selectedImage != null) {
                                      avatarUrl = await _uploadImage(_selectedImage!);
                                      if (avatarUrl == null) {
                                        setModalState(() => _isLoading = false);
                                        return; // Stop if image upload fails
                                      }
                                    }
                                    try {
                                      final newChat = await Supabase.instance.client.from('chats').insert({
                                        'user_id': userId,
                                        'created_at': DateTime.now().toIso8601String(),
                                        'name': _newChatNameController.text,
                                        'avatar': avatarUrl,
                                        'message': null,
                                        'unread': 0,
                                        'phone': _newChatPhoneController.text,
                                        'email': _newChatEmailController.text,
                                      }).select('id').maybeSingle();
                                      if (newChat == null) {
                                        throw Exception('Failed to create chat');
                                      }
                                      final newChatId = newChat['id'] as String;
                                      print('Inserting chat_users: chat_id=$newChatId, user_id=$userId'); // Debug
                                      await Supabase.instance.client.from('chat_users').upsert(
                                        {'chat_id': newChatId, 'user_id': userId},
                                        onConflict: 'chat_id,user_id', // Handle duplicate key
                                      );
                                      _newChatNameController.clear();
                                      _newChatPhoneController.clear();
                                      _newChatEmailController.clear();
                                      setModalState(() {
                                        _selectedImage = null;
                                        _isLoading = false; // Reset loading state
                                      });
                                      Navigator.pop(context);
                                    } catch (e) {
                                      setModalState(() => _isLoading = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error creating chat: $e'),
                                            backgroundColor: const Color(0xFF10214B),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10214B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Create', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteChat(String chatId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              child: Text('Cancel', style: TextStyle(fontSize: 16, color: Color(0xFF10214B))),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.from('chat_users').delete().eq('chat_id', chatId);
                await Supabase.instance.client.from('messages').delete().eq('chat_id', chatId);
                await Supabase.instance.client.from('chats').delete().eq('id', chatId);
                Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting chat: $e'),
                      backgroundColor: const Color(0xFF10214B),
                    ),
                  );
                }
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              child: Text('Delete', style: TextStyle(fontSize: 16, color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view chats')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10214B),
        title: const Text('Chats', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.normal)),
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('chat_users')
            .stream(primaryKey: ['chat_id'])
            .eq('user_id', userId)
            .asyncMap((chatUser) async {
              final chatIds = chatUser.map((cu) => cu['chat_id']).toList();
              if (chatIds.isEmpty) return [];
              final chats = await Supabase.instance.client
                  .from('chats')
                  .select('id, name, avatar, created_at, phone, email, unread')
                  .inFilter('id', chatIds);
              final chatsWithMessages = <Map<String, dynamic>>[];
              for (var chat in chats) {
                final latestMessage = await Supabase.instance.client
                    .from('messages')
                    .select('text')
                    .eq('chat_id', chat['id'])
                    .order('time', ascending: false)
                    .limit(1)
                    .maybeSingle();
                chatsWithMessages.add({
                  ...chat,
                  'last_message': latestMessage?['text'],
                });
              }
              return chatsWithMessages..sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
            }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10214B)));
          }
          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}'); // Debug
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Color(0xFF10214B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10214B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                    ),
                    child: const Text('Retry', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          }
          final chats = snapshot.data?.map((doc) => Chat.fromMap(doc)).toList() ?? [];
          final query = _searchController.text.toLowerCase();
          final filteredChats = chats.where((chat) {
            return chat.name.toLowerCase().contains(query) ||
                (chat.message?.toLowerCase().contains(query) ?? false) ||
                chat.phone.toLowerCase().contains(query) ||
                chat.email.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search Messenger...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF10214B)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Color(0xFF10214B), size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Active Chats',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10214B)),
                  ),
                ),
              ),
              Expanded(
                child: filteredChats.isEmpty
                    ? const Center(child: Text('No chats found. Add a new contact!', style: TextStyle(color: Color(0xFF10214B))))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          final isUnread = chat.unread > 0;
                          final timeFormat = DateFormat('h:mm a').format(chat.time);

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: chat.avatar.startsWith('http')
                                        ? CachedNetworkImageProvider(chat.avatar)
                                        : const AssetImage('assets/images/placeholder.png') as ImageProvider,
                                    onBackgroundImageError: (error, stackTrace) {
                                      print('Avatar load error for ${chat.name}: $error');
                                      return null;
                                    },
                                    child: chat.avatar.startsWith('http') ? null : const Icon(
                                      Icons.person,
                                      color: Color(0xFF10214B),
                                    ),
                                  ),
                                  if (index == 0)
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      chat.name,
                                      style: TextStyle(
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    timeFormat,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      chat.message ?? 'No messages yet',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Color(0xFF10214B), shape: BoxShape.circle),
                                      child: Text(
                                        chat.unread.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      contactName: chat.name,
                                      chatId: chat.id,
                                      avatar: chat.avatar,
                                    ),
                                  ),
                                ).then((_) {
                                  Supabase.instance.client.from('chats').update({'unread': 0}).eq('id', chat.id);
                                });
                              },
                              onLongPress: () => _deleteChat(chat.id),
                            ),
                          );
                        },
                      ),
                  ),
                ],
              );
            },
          ),
      );
  
    
  }
}