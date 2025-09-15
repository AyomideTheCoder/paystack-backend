import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String? text;
  final String? imageUrl;
  final DateTime time;
  final bool isSentByMe;
  bool isRead;

  Message({
    required this.id,
    this.text,
    this.imageUrl,
    required this.time,
    required this.isSentByMe,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'image_url': imageUrl,
        'time': time.toIso8601String(),
        'is_sent_by_me': isSentByMe,
        'is_read': isRead,
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id']?.toString() ?? '',
        text: map['text']?.toString(),
        imageUrl: map['image_url']?.toString(),
        time: DateTime.tryParse(map['time']?.toString() ?? '') ?? DateTime.now(),
        isSentByMe: map['is_sent_by_me'] as bool? ?? false,
        isRead: map['is_read'] as bool? ?? false,
      );
}

class ChatPage extends StatefulWidget {
  final String contactName;
  String chatId; // Changed from final to allow modification
  final String avatar;

  ChatPage({ // Removed const since chatId is now mutable
    required this.contactName,
    required this.chatId,
    required this.avatar,
    super.key,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isTyping = false;
  String? _uploadingImageId;
  XFile? _selectedImage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ensureChatUser();
    _loadMessages();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Ensure the current user is in chat_users table
  Future<void> _ensureChatUser() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to join the chat'),
            backgroundColor: Color(0xFF10214B),
          ),
        );
      }
      return;
    }

    try {
      // Refresh session if expired
      final session = client.auth.currentSession;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (session == null || (session.expiresAt != null && session.expiresAt! < now)) {
        await client.auth.refreshSession();
        debugPrint('Session refreshed successfully in ChatPage');
      }

      // Ensure chat_user entry exists
      await client.from('chat_users').upsert({
        'chat_id': widget.chatId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      }, onConflict: 'chat_id,user_id');

      debugPrint('Ensured chat_users entry: chat_id=${widget.chatId}, user_id=$userId');
    } catch (e) {
      debugPrint('Error ensuring chat_user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session expired or error occurred. Please log in again.'),
            action: SnackBarAction(
              label: 'Log In',
              onPressed: () => Navigator.pushReplacementNamed(context, '/splash'),
            ),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
      }
    }
  }

  /// Create a new chat if chatId is empty or new
  Future<void> _createNewChat() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) return;

    try {
      // Generate a new chatId
      final newChatId = const Uuid().v4();

      // Insert chat_users for current user
      await client.from('chat_users').insert({
        'chat_id': newChatId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        widget.chatId = newChatId; // Update widget.chatId for future messages
      });

      debugPrint('New chat created with chatId=$newChatId for userId=$userId');
    } catch (e) {
      debugPrint('Error creating new chat: $e');
    }
  }

  void _loadMessages() {
    setState(() => _isLoading = true);
    Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', widget.chatId)
        .order('time', ascending: true)
        .listen((List<Map<String, dynamic>> data) {
      if (mounted) {
        setState(() {
          _messages = data.map((doc) => Message.fromMap(doc)).toList();
          _isLoading = false;
        });
        _markMessagesAsRead();
        _scrollToBottom();
      }
    }, onError: (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $error'),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
        setState(() => _isLoading = false);
      }
    });
  }

  void _markMessagesAsRead() async {
    final myUserId = Supabase.instance.client.auth.currentUser?.id;
    if (myUserId != null) {
      try {
        await Supabase.instance.client
            .from('messages')
            .update({'is_read': true})
            .eq('chat_id', widget.chatId)
            .eq('is_sent_by_me', false)
            .eq('is_read', false);
      } catch (e) {
        debugPrint('Failed to mark messages as read: $e');
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      setState(() => _uploadingImageId = '${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}');
      final fileName = 'chat_images/${user.id}/${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) return null;
        await Supabase.instance.client.storage.from('chat_images').uploadBinary(fileName, bytes);
      } else {
        final file = File(image.path);
        if (await file.length() > 5 * 1024 * 1024) return null;
        await Supabase.instance.client.storage.from('chat_images').upload(fileName, file);
      }

      final imageUrl = Supabase.instance.client.storage.from('chat_images').getPublicUrl(fileName);
      setState(() => _uploadingImageId = null);
      return imageUrl;
    } catch (e) {
      setState(() => _uploadingImageId = null);
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _attachFile() async {
    if (_isSending) return;
    try {
      setState(() => _isSending = true);
      XFile? pickedFile;
      if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
        if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
          pickedFile = XFile(result.files.single.path!);
        } else {
          setState(() => _isSending = false);
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (status.isGranted) {
          pickedFile = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 80,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo permission denied.'),
                backgroundColor: Color(0xFF10214B),
              ),
            );
          }
          setState(() => _isSending = false);
          return;
        }
      }

      if (pickedFile != null && mounted) {
        setState(() => _selectedImage = pickedFile);
        final imageUrl = await _uploadImage(pickedFile);
        if (imageUrl != null) _sendMessage(imageUrl: imageUrl);
        setState(() => _selectedImage = null);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _selectedImage = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error attaching file: $e'),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _captureImage() async {
    if (_isSending) return;
    try {
      setState(() => _isSending = true);
      if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera not supported on this platform'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
        setState(() => _isSending = false);
        return;
      }

      final status = await Permission.camera.request();
      if (status.isGranted && mounted) {
        final pickedFile = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
        );
        if (pickedFile != null) {
          setState(() => _selectedImage = pickedFile);
          final imageUrl = await _uploadImage(pickedFile);
          if (imageUrl != null) _sendMessage(imageUrl: imageUrl);
          setState(() => _selectedImage = null);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission denied.'),
              backgroundColor: Color(0xFF10214B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _selectedImage = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Send a message (text or image)
  void _sendMessage({String? imageUrl}) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null || (_messageController.text.isEmpty && imageUrl == null) || _isSending) return;

    setState(() {
      _isTyping = false;
      _isSending = true;
    });

    // Create new chat if chatId is null or empty
    if (widget.chatId.isEmpty) {
      await _createNewChat();
    }

    final newMessage = Message(
      id: const Uuid().v4(),
      text: _messageController.text.isNotEmpty ? _messageController.text : null,
      imageUrl: imageUrl,
      time: DateTime.now(),
      isSentByMe: true,
    );

    try {
      // Refresh session if expired
      final session = client.auth.currentSession;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (session == null || (session.expiresAt != null && session.expiresAt! < now)) {
        await client.auth.refreshSession();
        debugPrint('Session refreshed successfully for sending message');
      }

      await client.from('messages').insert({
        ...newMessage.toMap(),
        'chat_id': widget.chatId,
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session expired or error occurred. Please log in again.'),
            action: SnackBarAction(
              label: 'Log In',
              onPressed: () => Navigator.pushReplacementNamed(context, '/splash'),
            ),
            backgroundColor: const Color(0xFF10214B),
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _deleteMessage(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
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
                await Supabase.instance.client
                    .from('messages')
                    .delete()
                    .eq('id', message.id)
                    .eq('chat_id', widget.chatId);
                Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting message: $e'),
                      backgroundColor: const Color(0xFF10214B),
                    ),
                  );
                }
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text('Delete', style: TextStyle(fontSize: 16, color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  void _viewImage(String? imageUrl) {
    if (imageUrl == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.error,
              color: Color(0xFF10214B),
              size: 50,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 28, 56, 128), Color(0xFF10214B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.avatar.startsWith('http')
                  ? CachedNetworkImageProvider(widget.avatar)
                  : const AssetImage('assets/placeholder.png') as ImageProvider,
              onBackgroundImageError: (error, stackTrace) {},
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contactName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text('Online', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10214B)))
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(child: Text('No messages yet', style: TextStyle(color: Color(0xFF10214B))))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _messages.length,
                          cacheExtent: 1000,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return GestureDetector(
                              onLongPress: () => _deleteMessage(message),
                              child: message.imageUrl != null
                                  ? GestureDetector(
                                      onTap: () => _viewImage(message.imageUrl),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        alignment: message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: message.imageUrl!,
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(child: CircularProgressIndicator(color: Color(0xFF10214B))),
                                            errorWidget: (context, url, error) => const Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      alignment: message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                        color: message.isSentByMe ? const Color(0xFF10214B) : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        message.text ?? '',
                                        style: TextStyle(
                                          color: message.isSentByMe ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _attachFile,
                        icon: const Icon(Icons.attach_file, color: Color(0xFF10214B)),
                      ),
                      IconButton(
                        onPressed: _captureImage,
                        icon: const Icon(Icons.camera_alt, color: Color(0xFF10214B)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onChanged: (text) => setState(() => _isTyping = text.isNotEmpty),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration.collapsed(hintText: 'Type a message...'),
                        ),
                      ),
                      IconButton(
                        onPressed: _isTyping || _selectedImage != null ? _sendMessage : null,
                        icon: const Icon(Icons.send, color: Color(0xFF10214B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}