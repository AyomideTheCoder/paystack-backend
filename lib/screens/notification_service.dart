import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<Map<String, dynamic>> _notifications = [];
  final ValueNotifier<int> notificationCount = ValueNotifier<int>(0);

  bool _isInitialized = false;

  // 🔑 Constants
  static const String _channelId = 'naija_market_channel';
  static const String _channelName = 'Naija Market Notifications';
  static const String _channelDescription =
      'Notifications for Naija Market actions';

  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);

  /// Check if running on web
  bool get _isWeb {
    try {
      return !Platform.isAndroid && !Platform.isIOS;
    } catch (e) {
      return true; // Assume web if Platform check fails
    }
  }

  /// Initialize notifications (idempotent)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!_isWeb) {
        const initializationSettings = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        );

        // Request permissions
        if (Platform.isAndroid) {
          final androidPlugin = _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          await androidPlugin?.requestNotificationsPermission();
        } else if (Platform.isIOS) {
          final iosPlugin = _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>();
          await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        }

        await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
        debugPrint('NotificationService: Local notifications initialized');
      } else {
        debugPrint('NotificationService: Skipping local notifications on web');
      }

      await loadNotifications();
      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      await loadNotifications(); // Load notifications even if local notifications fail
    }
  }

  /// Show a notification and persist it
  Future<void> showNotification(String title, String body) async {
    await initialize();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('No user logged in, skipping notification persistence');
      return;
    }

    try {
      // Save to Supabase first
      final notification = await _addNotification(title, body, user.id);
      if (notification == null) {
        debugPrint('Failed to save notification to Supabase');
        return;
      }

      // Show local notification (skip on web)
      if (!_isWeb) {
        const androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );

        const notificationDetails = NotificationDetails(android: androidDetails);

        final id = _notifications.length; // Sequential ID for system notification
        await _flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          notificationDetails,
        );
      }

      // Add to local list and update count
      _notifications.add(notification);
      updateNotificationCount();
      debugPrint('Notification shown and saved: $title - $body');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Add notification to Supabase and return the notification if successful
  Future<Map<String, dynamic>?> _addNotification(
      String title, String body, String userId) async {
    final timestamp = DateTime.now();
    final notification = {
      'id': timestamp.millisecondsSinceEpoch, // Store as bigint
      'user_id': userId,
      'title': title,
      'body': body,
      'is_read': false,
      'timestamp': timestamp.toIso8601String(),
    };

    try {
      await Supabase.instance.client.from('notifications').insert(notification);
      return notification;
    } catch (e) {
      debugPrint('Error saving notification to Supabase: $e');
      return null;
    }
  }

  /// Get formatted timestamp (e.g., "2 minutes ago")
  String getFormattedTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return timeago.format(dateTime, allowFromNow: true);
    } catch (e) {
      debugPrint('Error parsing timestamp: $e');
      return 'Just now';
    }
  }

  /// Update count of unread notifications
  void updateNotificationCount() {
    notificationCount.value =
        _notifications.where((n) => n['is_read'] == false).length;
    debugPrint('Notification count updated: ${notificationCount.value}');
  }

  /// Load notifications from Supabase
  Future<void> loadNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('No user logged in, skipping notification load');
      _notifications.clear();
      updateNotificationCount();
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false);

      debugPrint('Raw response from Supabase: $response');
      _notifications.clear();
      _notifications.addAll(response.cast<Map<String, dynamic>>());
      debugPrint('Loaded ${_notifications.length} notifications: $_notifications');
      updateNotificationCount();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      _notifications.clear();
      updateNotificationCount();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('No user logged in, skipping mark all as read');
      return;
    }

    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      for (var n in _notifications) {
        n['is_read'] = true;
      }
      updateNotificationCount();
      debugPrint('All notifications marked as read');
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  /// Remove a single notification by id
  Future<void> removeNotification(String id) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('No user logged in, skipping notification removal');
      return;
    }

    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);

      _notifications.removeWhere((n) => n['id']?.toString() == id);
      updateNotificationCount();
      debugPrint('Notification removed: $id');
    } catch (e) {
      debugPrint('Error removing notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('No user logged in, skipping clear notifications');
      _notifications.clear();
      updateNotificationCount();
      return;
    }

    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', user.id);

      _notifications.clear();
      updateNotificationCount();
      debugPrint('Notifications cleared');
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }
}