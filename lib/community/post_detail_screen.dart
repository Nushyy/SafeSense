import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'community_data.dart';
import 'post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_isSending) return;

    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    if (text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Replies must be 2000 characters or fewer.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await communityRepo.addComment(widget.post, text);
      if (!mounted) return;
      // Only clear the text submitted. Preserve anything typed while awaiting.
      if (_replyController.text.trim() == text) {
        _replyController.clear();
      }
      FocusScope.of(context).unfocus();
    } catch (error) {
      debugPrint('Community reply submission failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send your reply. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Retrieve the latest version of this post after a repository refresh.
          final matchingPosts = communityRepo.posts().where(
                (item) => item.id == widget.post.id,
              );
          final currentPost = matchingPosts.isNotEmpty
              ? matchingPosts.first
              : widget.post;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PostCard(
                      post: currentPost,
                      expanded: true,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Replies (${currentPost.comments.length})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (currentPost.comments.isEmpty)
                      const Text(
                        'No replies yet. Add the first one below.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    for (final comment in currentPost.comments)
                      _CommentTile(comment: comment),
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
                            enabled: !_isSending,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: 2000,
                            decoration: InputDecoration(
                              hintText: 'Write a reply',
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.softSurface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _sendReply(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                          onPressed: _isSending ? null : _sendReply,
                          icon: _isSending
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          tooltip: _isSending ? 'Sending reply' : 'Send reply',
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
                        child: Text(
                          comment.author.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (comment.author.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.text,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPostTime(comment.createdAt),
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
