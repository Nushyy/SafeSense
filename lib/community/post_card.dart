import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'community_data.dart';
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
  final PostCategory category;
  const CategoryTag({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.tagLabel,
        style: TextStyle(
          color: category.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  /// false in the feed (body is cut after 3 lines), true on the detail screen.
  final bool expanded;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final area = communityRepo.suburbById(post.areaId);

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
                // Footer: share, comments, area
                Row(
                  children: [
                    Builder(
                      builder: (buttonContext) => InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => sharePost(buttonContext, post),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.share_outlined,
                                  size: 20, color: AppColors.textSecondary),
                              SizedBox(width: 6),
                              Text('Share',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline,
                        size: 19, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('${post.comments.length}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const Spacer(),
                    const Icon(Icons.place_outlined,
                        size: 16, color: AppColors.textLight),
                    const SizedBox(width: 2),
                    Text(area?.name ?? '',
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 12)),
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

  void _zoom(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.memory(attachment.bytes)),
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
              child: Image.memory(
                attachment.bytes,
                width: double.infinity,
                height: pictureHeight,
                fit: BoxFit.cover,
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
    return Container(
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
    );
  }
}