// models/chat.dart

class User {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });
}

class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final String senderId;
  final bool isRead;
  final bool isDelivered;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.senderId,
    this.isRead = false,
    this.isDelivered = false,
  });
}

class Chat {
  final String id;
  final User user;
  final List<Message> messages;

  Chat({
    required this.id,
    required this.user,
    required this.messages,
  });

  Message get lastMessage => messages.isNotEmpty
      ? messages.last
      : Message(
          id: '',
          text: '',
          timestamp: DateTime.now(),
          senderId: '',
        );
}
