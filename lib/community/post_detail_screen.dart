import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'community_data.dart';
import 'post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    _replyController.clear();
    await communityRepo.addComment(widget.post, text);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
        title: const Text('Post'),
      ),
      body: AnimatedBuilder(
        animation: communityRepo,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PostCard(
                      post: post,
                      expanded: true,
                      onLike: () => communityRepo.toggleLike(post),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Replies (${post.comments.length})',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    if (post.comments.isEmpty)
                      const Text('No replies yet. Add the first one below.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    for (final c in post.comments) _CommentTile(comment: c),
                  ],
                ),
              ),
              Container(
                color: AppColors.surface,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Write a reply',
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
                          onPressed: _sendReply,
                          icon: const Icon(Icons.send),
                          tooltip: 'Send reply',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(user: comment.author, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(comment.author.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                      if (comment.author.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 14, color: AppColors.primaryBlue),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(comment.text,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(formatPostTime(comment.createdAt),
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}