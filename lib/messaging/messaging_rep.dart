import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../community/community_data.dart';
import '../theme/app_colors.dart';

class DirectMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final DateTime? readAt;

  const DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.readAt,
  });

  factory DirectMessage.fromRow(Map<String, dynamic> r) => DirectMessage(
        id: r['id'] as String,
        conversationId: r['conversation_id'] as String,
        senderId: r['sender_id'] as String,
        text: r['body'] as String,
        createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
        readAt: r['read_at'] == null
            ? null
            : DateTime.parse(r['read_at'] as String).toLocal(),
      );
}

class Conversation {
  final String id;
  final AppUser other; // the person you are chatting with
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unread;

  const Conversation({
    required this.id,
    required this.other,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unread,
  });
}

/// Private one-to-one messages stored in Supabase.
/// Tables and security rules: supabase/messaging.sql
class MessagingRepository {
  MessagingRepository._();
  static final MessagingRepository instance = MessagingRepository._();

  static const _avatarColors = [
    AppColors.primaryBlue,
    AppColors.darkBlue,
    AppColors.heroBlue,
    AppColors.success,
    AppColors.warning,
    AppColors.danger,
  ];

  /// false while the app is running on dummy data (Supabase not started).
  static bool get isAvailable {
    try {
      sb.Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  sb.SupabaseClient get _db => sb.Supabase.instance.client;

  /// The signed-in user's id (null if not signed in yet).
  String? get myId => _db.auth.currentUser?.id;

  final Map<String, AppUser> _profiles = {};

  AppUser _userFrom(Map? m, String fallbackId) {
    final id = (m?['id'] as String?) ?? fallbackId;
    return AppUser(
      id: id,
      name: (m?['display_name'] as String?) ?? 'Neighbour',
      color: _avatarColors[
          id.codeUnits.fold<int>(0, (a, b) => a + b) % _avatarColors.length],
      verified: (m?['verified'] as bool?) ?? false,
    );
  }

  Future<void> _loadProfiles(Set<String> ids) async {
    final missing = ids.where((id) => !_profiles.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final rows = await _db
        .from('public_profiles')
        .select('id, display_name, verified')
        .inFilter('id', missing);
    for (final r in rows) {
      final m = Map<String, dynamic>.from(r as Map);
      _profiles[m['id'] as String] = _userFrom(m, m['id'] as String);
    }
  }

  /// Opens (or creates) the private chat with [otherUserId]. Returns the conversation id.
  Future<String> startConversation({
    required String otherUserId,
    String? postId,
  }) async {
    final id = await _db.rpc('start_conversation', params: {
      'other_user': otherUserId,
      'from_post': postId,
    });
    return id as String;
  }

  /// Your inbox, newest chat first. Updates live when a message arrives.
  Stream<List<Conversation>> watchConversations() {
    final me = myId!;
    return _db
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .asyncMap((rows) async {
      final otherIds = <String, String>{
        for (final r in rows)
          r['id'] as String:
              (r['user_a'] == me ? r['user_b'] : r['user_a']) as String,
      };
      await _loadProfiles(otherIds.values.toSet());
      final unread = await _unreadByConversation(me);
      return [
        for (final r in rows)
          Conversation(
            id: r['id'] as String,
            other: _profiles[otherIds[r['id']]] ??
                _userFrom(null, otherIds[r['id']]!),
            lastMessage: (r['last_message_preview'] as String?) ?? '',
            lastMessageAt:
                DateTime.parse(r['last_message_at'] as String).toLocal(),
            unread: unread[r['id']] ?? 0,
          ),
      ];
    });
  }

  Future<Map<String, int>> _unreadByConversation(String me) async {
    final rows = await _db
        .from('messages')
        .select('conversation_id')
        .isFilter('read_at', null)
        .neq('sender_id', me);
    final counts = <String, int>{};
    for (final r in rows) {
      final id = (r as Map)['conversation_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  /// Messages of one chat, NEWEST FIRST (the screen shows them bottom-up).
  Stream<List<DirectMessage>> watchMessages(String conversationId) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(200)
        .map((rows) => [
              for (final r in rows)
                DirectMessage.fromRow(Map<String, dynamic>.from(r)),
            ]);
  }

  Future<void> send(String conversationId, String text) async {
    await _db.from('messages').insert({
      'conversation_id': conversationId,
      'body': text,
    });
  }

  /// Marks the other person's messages in this chat as read.
  Future<void> markRead(String conversationId) async {
    try {
      await _db
          .from('messages')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', myId!)
          .isFilter('read_at', null);
    } catch (e) {
      debugPrint('markRead failed: $e');
    }
  }
}