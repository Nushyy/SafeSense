
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();

  static final SupabaseClient _client =
      Supabase.instance.client;

  static String? get _userId =>
      _client.auth.currentUser?.id;

  // Listen for changes to the current user's notifications.
  static Stream<List<Map<String, dynamic>>> watchNotifications() {
    final userId = _userId;

    if (userId == null) {
      return Stream.value(<Map<String, dynamic>>[]);
    }

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((row) => Map<String, dynamic>.from(row))
              .toList(),
        );
  }

  // Mark a notification as read.
  static Future<void> markAsRead(String notificationId) async {
    final userId = _userId;

    if (userId == null) {
      throw StateError('You must be signed in.');
    }

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  // Mark all notifications as read.
  static Future<void> markAllAsRead() async {
    final userId = _userId;

    if (userId == null) {
      throw StateError('You must be signed in.');
    }

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}

