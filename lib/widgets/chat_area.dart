import 'package:flutter/material.dart';

class ChatArea extends StatefulWidget {
  final Map<String, String>? selectedChat;

  const ChatArea({super.key, this.selectedChat});

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final List<Map<String, dynamic>> _messages = [
    {"sender": "Aminu", "text": "Wetin dey happen?", "time": "12:30 PM", "isMe": false},
    {"sender": "Me", "text": "Everything dey cool!", "time": "12:31 PM", "isMe": true},
    {"sender": "Aminu", "text": "Good to know!", "time": "12:32 PM", "isMe": false},
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && widget.selectedChat != null) {
      setState(() {
        _messages.add({
          "sender": "Me",
          "text": _messageController.text.trim(),
          "time": TimeOfDay.now().format(context),
          "isMe": true,
        });
        _messageController.clear();
      });

      // Scroll to the bottom after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0AAD69), Color(0xFF056C4D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          if (widget.selectedChat == null)
            const Expanded(
              child: Center(
                child: Text(
                  "Select a chat to start messaging",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Chat Header
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: const Color(0xFF004d40),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(widget.selectedChat!["avatar"]!),
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.selectedChat!["name"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chat Messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final bool isMe = message["isMe"] == true;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.white : const Color(0xFF00796b),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message["text"],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message["time"],
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Message Input
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: const Color(0xFF004d40),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: const TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF0AAD69)),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
