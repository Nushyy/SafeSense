import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'community_data.dart';

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

  /// False in the feed; true on the detail screen.
  final bool expanded;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    // Re-read the post after a repository refresh, since Supabase returns
    // new Post objects rather than mutating the previous instance.
    return AnimatedBuilder(
      animation: communityRepo,
      builder: (context, _) {
        final matches = communityRepo.posts().where((p) => p.id == post.id);
        final displayedPost = matches.isNotEmpty ? matches.first : post;
        final area = communityRepo.suburbById(displayedPost.areaId);

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
                padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        UserAvatar(user: displayedPost.author),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayedPost.author.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (displayedPost.author.verified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified,
                                        size: 16, color: AppColors.primaryBlue),
                                  ],
                                ],
                              ),
                              Text(
                                formatPostTime(displayedPost.createdAt),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: CategoryTag(category: displayedPost.category)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayedPost.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayedPost.body,
                      maxLines: expanded ? null : 3,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    if (displayedPost.hasImage) ...[
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
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 19, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${displayedPost.comments.length}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.place_outlined,
                            size: 16, color: AppColors.textLight),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            area?.label ?? displayedPost.areaId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
