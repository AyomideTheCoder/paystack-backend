class MessageModel {
  final String text;
  final bool isSentByMe;
  final DateTime time;

  MessageModel({
    required this.text,
    required this.isSentByMe,
    required this.time,
  });
}
