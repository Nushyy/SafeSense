import 'dart:async';
import 'package:flutter/material.dart';
import '../community/community_data.dart';
import '../community/post_card.dart' show UserAvatar;
import '../theme/app_colors.dart';
import 'messaging_rep.dart';

/// Called by the "Message" button on a post: opens (or creates) the private chat
/// with the post's author and shows the chat screen.
Future<void> openPrivateChat(BuildContext context, Post post) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    final conversationId = await MessagingRepository.instance.startConversation(
      otherUserId: post.author.id,
      postId: post.id,
    );
    navigator.push(MaterialPageRoute(
      builder: (_) =>
          PrivateChatScreen(conversationId: conversationId, other: post.author),
    ));
  } catch (e) {
    debugPrint('openPrivateChat failed: $e');
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open the chat. Please try again.')),
    );
  }
}

class PrivateChatScreen extends StatefulWidget {
  final String conversationId;
  final AppUser other;
  const PrivateChatScreen({
    super.key,
    required this.conversationId,
    required this.other,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _repo = MessagingRepository.instance;
  final _controller = TextEditingController();
  StreamSubscription<List<DirectMessage>>? _sub;
  List<DirectMessage>? _messages; // newest first
  bool _failed = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _sub = _repo.watchMessages(widget.conversationId).listen(
      (list) {
        if (!mounted) return;
        setState(() => _messages = list);
        // Mark the other person's messages as read while this chat is open.
        final me = _repo.myId;
        if (list.any((m) => m.senderId != me && m.readAt == null)) {
          _repo.markRead(widget.conversationId);
        }
      },
      onError: (Object e) {
        debugPrint('Chat stream error: $e');
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      await _repo.send(widget.conversationId, text);
    } catch (e) {
      debugPrint('send failed: $e');
      if (!mounted) return;
      _controller.text = text; // give the text back so nothing is lost
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message not sent. Check your connection.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _repo.myId;
    final messages = _messages;

    Widget body;
    if (_failed) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Could not load this chat. Go back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    } else if (messages == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (messages.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Say hello to ${widget.other.name}. Only the two of you can see this chat.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    } else {
      body = ListView.builder(
        reverse: true, // newest message at the bottom
        padding: const EdgeInsets.all(12),
        itemCount: messages.length,
        itemBuilder: (context, i) =>
            _MessageBubble(message: messages[i], isMine: messages[i].senderId == me),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(user: widget.other, radius: 16),
            const SizedBox(width: 10),
            Flexible(
              child: Text(widget.other.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (widget.other.verified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.lightBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'Private chat. Do not share your ID number, bank details or home address. In an emergency, call 10111.',
              style: TextStyle(color: AppColors.darkBlue, fontSize: 12),
            ),
          ),
          Expanded(child: body),
          Container(
            color: AppColors.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        buildCounter: (_,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            null,
                        decoration: InputDecoration(
                          hintText: 'Write a message',
                          filled: true,
                          fillColor: AppColors.softSurface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue),
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                      tooltip: 'Send',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bg = isMine ? AppColors.primaryBlue : AppColors.surface;
    final fg = isMine ? Colors.white : AppColors.textPrimary;
    final sub = isMine ? Colors.white70 : AppColors.textLight;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: isMine ? null : Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.text, style: TextStyle(color: fg, fontSize: 15)),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_time(message.createdAt),
                        style: TextStyle(color: sub, fontSize: 10)),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.readAt == null ? Icons.check : Icons.done_all,
                        size: 12,
                        color: sub,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}