import 'package:flutter/material.dart';
import 'package:wear_space/screens/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    debugPrint('NotificationsPage initState: Initializing NotificationService');
    _notificationService.initialize().then((_) {
      debugPrint('NotificationsPage: Loading initial notifications');
      _notificationService.loadNotifications().then((_) {
        setState(() {});
      });
    });
  }

  Future<void> markAllAsRead() async {
    try {
      debugPrint('Marking all notifications as read');
      await _notificationService.markAllAsRead();
      setState(() {});
    } catch (e) {
      debugPrint('Failed to mark notifications as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark notifications as read: $e'),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  Future<void> removeNotification(String id) async {
    try {
      debugPrint('Removing notification with id: $id');
      await _notificationService.removeNotification(id);
      setState(() {});
    } catch (e) {
      debugPrint('Failed to remove notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove notification: $e'),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: _notificationService.notificationCount,
          builder: (context, count, _) {final notifications = List<Map<String, dynamic>>.from(_notificationService.notifications)
  ..sort((a, b) {
    final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime); // latest first
  });

            debugPrint('Building NotificationsPage UI with $count notifications: $notifications');

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF10214B)),
                            tooltip: 'Back',
                            splashRadius: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Notifications',
                            style: theme.textTheme.titleLarge?.copyWith(
                                  color: const Color(0xFF10214B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20, // Reduced from 22 to 20
                                ) ??
                                const TextStyle(
                                  color: Color(0xFF10214B),
                                  fontSize: 20, // Reduced from 22 to 20
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: notifications.isEmpty ? null : markAllAsRead,
                            child: const Text(
                              'Mark All as Read',
                              style: TextStyle(
                                color: Color(0xFF10214B),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (notifications.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No notifications available',
                          style: TextStyle(
                            color: Color(0xFF10214B),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: notifications.map((notification) {
                        final String id = notification['id']?.toString() ?? '';
                        debugPrint('Rendering notification: $notification');

                        return Dismissible(
                          key: ValueKey(id),
                          onDismissed: (_) => removeNotification(id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10214B),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white, size: 24),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10214B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_active,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                notification['title'] ?? 'Notification',
                                style: TextStyle(
                                  fontWeight: notification['is_read'] == true
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color: const Color(0xFF10214B),
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                notification['body'] ?? 'No content',
                                style: const TextStyle(
                                  color: Color(0xFF10214B),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _notificationService.getFormattedTimestamp(
                                        notification['timestamp'] ?? ''),
                                    style: const TextStyle(
                                      color: Color(0xFF10214B),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    Icons.circle,
                                    color: notification['is_read'] == true
                                        ? Colors.grey
                                        : const Color(0xFF10214B),
                                    size: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}