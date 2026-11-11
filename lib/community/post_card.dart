import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import 'community_data.dart';
import '../messaging/messaging_rep.dart';
import '../messaging/private_chat_screen.dart';
import 'share_post_screen.dart';

class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double radius;
  const UserAvatar({super.key, required this.user, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: user.color,
      child: Text(
        user.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

class CategoryTag extends StatelessWidget {
  final CrimeCategory category;
  const CategoryTag({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: category.color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  /// Tapping the comment icon (opens the post with the reply box ready).
  final VoidCallback? onComment;

  /// false in the feed (body is cut after 3 lines), true on the detail screen.
  final bool expanded;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onComment,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final area =
        post.areaId == null ? null : communityRepo.suburbById(post.areaId!);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    UserAvatar(user: post.author),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.author.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (post.author.verified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified,
                                    size: 16, color: AppColors.primaryBlue),
                              ],
                            ],
                          ),
                          Text(
                            formatPostTime(post.createdAt),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CategoryTag(category: post.category),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  post.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post.body,
                  maxLines: expanded ? null : 3,
                  overflow: expanded ? null : TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (post.attachment != null) ...[
                  const SizedBox(height: 12),
                  AttachmentView(
                      attachment: post.attachment!,
                      pictureHeight: expanded ? 260 : 180),
                ] else if (post.hasImage) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.textLight, size: 36),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 8),
                // Footer: comment | message privately | share            area
                Row(
                  children: [
                    Tooltip(
                      message: 'Comment',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onComment,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline,
                                  size: 20, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text('${post.comments.length}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Message the author privately (not shown on your own posts).
                    if (post.author.id != communityRepo.currentUser.id) ...[
                      const SizedBox(width: 12),
                      Tooltip(
                        message: 'Message privately',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (!MessagingRepository.isAvailable) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Private messages need the database connection.'),
                                ),
                              );
                              return;
                            }
                            openPrivateChat(context, post);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.mail_outline,
                                size: 20, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Builder(
                      builder: (buttonContext) => Tooltip(
                        message: 'Share',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => sharePost(buttonContext, post),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.share_outlined,
                                size: 20, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.place_outlined,
                        size: 16, color: AppColors.textLight),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(area?.name ?? post.otherArea ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a post's picture or document.
/// Pass [onRemove] on the create screen to show a remove (X) button.
class AttachmentView extends StatelessWidget {
  final PostAttachment attachment;
  final double pictureHeight;
  final VoidCallback? onRemove;
  const AttachmentView({
    super.key,
    required this.attachment,
    this.pictureHeight = 180,
    this.onRemove,
  });

  /// Local picture (just picked) or picture saved in Supabase Storage.
  Widget _image({required BoxFit fit, double? width, double? height}) {
    final bytes = attachment.bytes;
    if (bytes != null) {
      return Image.memory(bytes, width: width, height: height, fit: fit);
    }
    final url = attachment.url;
    if (url != null) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => SizedBox(
          width: width,
          height: height ?? 120,
          child: const Center(
            child: Icon(Icons.broken_image_outlined,
                color: AppColors.textLight, size: 32),
          ),
        ),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : SizedBox(
                width: width,
                height: height ?? 120,
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
      );
    }
    return const SizedBox.shrink();
  }

  void _zoom(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: _image(fit: BoxFit.contain)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final removeButton = onRemove == null
        ? null
        : IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.textSecondary,
            tooltip: 'Remove',
            onPressed: onRemove,
          );

    if (attachment.type == AttachmentType.picture) {
      return GestureDetector(
        onTap: () => _zoom(context),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _image(
                fit: BoxFit.cover,
                width: double.infinity,
                height: pictureHeight,
              ),
            ),
            if (onRemove != null)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final isPdf = attachment.name.toLowerCase().endsWith('.pdf');
    final url = attachment.url;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: url == null
          ? null
          : () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
            color: isPdf ? AppColors.danger : AppColors.primaryBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Text(
                  attachment.sizeLabel,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (removeButton != null) removeButton else const SizedBox(width: 8),
        ],
      ),
    ),
    );
  }
}