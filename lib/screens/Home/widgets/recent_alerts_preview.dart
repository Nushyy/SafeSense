import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../community/community_data.dart';
import '../../../community/post_card.dart';
import '../../../community/post_detail_screen.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

class RecentAlertsPreview extends StatefulWidget {
  const RecentAlertsPreview({super.key});

  @override
  State<RecentAlertsPreview> createState() => _RecentAlertsPreviewState();
}

class _RecentAlertsPreviewState extends State<RecentAlertsPreview> {
  @override
  void initState() {
    super.initState();

    // Refresh Bulletin Board posts when the Home screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final repo = communityRepo;

      if (repo is SupabaseCommunityRepository) {
        repo.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bulletin Board heading and navigation.
          Row(
            children: [
              const Icon(Icons.campaign_outlined, color: AppColors.navy),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Community Bulletin Board',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/alerts'),
                child: const Text('See all'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Listen for updates from the shared community repository.
          AnimatedBuilder(
            animation: communityRepo,
            builder: (context, _) {
              final posts = communityRepo.posts();

              final repo = communityRepo is SupabaseCommunityRepository
                  ? communityRepo as SupabaseCommunityRepository
                  : null;

              // Loading state.
              if (repo?.isLoadingPosts == true && posts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Error state.
              if (repo?.postsError != null && posts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Unable to load Bulletin Board posts.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              // Empty state.
              if (posts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No Bulletin Board posts yet. '
                    'Community updates will appear here.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              // The repository returns posts newest first.
              final latestPost = posts.first;

              // Display only the latest post.
              return PostCard(
                post: latestPost,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(post: latestPost),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
