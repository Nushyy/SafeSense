import 'package:flutter/material.dart';
import '../community/community_data.dart';
import '../community/post_card.dart' show UserAvatar;
import '../theme/app_colors.dart';
import 'messaging_rep.dart';
import 'private_chat_screen.dart';

/// List of all your private chats.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  // Created only when messaging is available (late = built on first use).
  late Stream<List<Conversation>> _stream =
      MessagingRepository.instance.watchConversations();

  /// Re-load after coming back from a chat so the unread badges are correct.
  void _reload() => setState(
      () => _stream = MessagingRepository.instance.watchConversations());

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!MessagingRepository.isAvailable) {
      body = _message('Messages need the database connection.');
    } else if (MessagingRepository.instance.myId == null) {
      body = _message('Sign in to see your messages.');
    } else {
      body = StreamBuilder<List<Conversation>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message('Could not load your messages. Try again later.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return _message(
                'No messages yet. Tap "Message" on a post to start a private chat.');
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, i) {
              final c = chats[i];
              return Material(
                color: AppColors.surface,
                child: ListTile(
                  leading: UserAvatar(user: c.other),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(c.other.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: c.unread > 0
                                    ? FontWeight.w800
                                    : FontWeight.w600)),
                      ),
                      if (c.other.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 15, color: AppColors.primaryBlue),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    c.lastMessage.isEmpty ? 'No messages yet' : c.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.unread > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontStyle: c.lastMessage.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatPostTime(c.lastMessageAt),
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 11)),
                      if (c.unread > 0) ...[
                        const SizedBox(height: 4),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primaryBlue,
                          child: Text('${c.unread > 9 ? '9+' : c.unread}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivateChatScreen(
                            conversationId: c.id, other: c.other),
                      ),
                    );
                    if (mounted) _reload();
                  },
                ),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
        title: const Text('Messages'),
      ),
      body: body,
    );
  }
}
 