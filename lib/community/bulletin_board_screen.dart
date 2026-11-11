import 'package:flutter/material.dart';
import '../messaging/inbox_screen.dart';
import '../messaging/messaging_rep.dart';
import '../theme/app_colors.dart';
import 'area_picker.dart';
import 'bottom_nav_scaffold.dart';
import 'community_data.dart';
import 'create_post_screen.dart';
import 'post_card.dart';
import 'post_detail_screen.dart';

class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  State<BulletinBoardScreen> createState() =>
      _BulletinBoardScreenState();
}

class _BulletinBoardScreenState
    extends State<BulletinBoardScreen> {
  Suburb? _area;
  CrimeCategory? _category;

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(initialArea: _area),
      ),
    );
  }

  Future<void> _openAreaPicker() async {
    final choice = await showAreaPicker(
      context,
      selected: _area,
      allowAll: true, // "Other" is only offered on the Create post screen
    );
    if (choice == null) return;
    setState(() => _area = choice.area);
  }

  void _openPostDetail(Post post, {bool focusReply = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post, focusReply: focusReply),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavScaffold(
      currentIndex: 3,
      title: 'Alerts',
      child: Column(
        children: [
          _Header(
            area: _area,
            category: _category,
            onPost: _openCreatePost,
            onAreaTap: _openAreaPicker,
            onCategory: (category) {
              setState(() => _category = category);
            },
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: communityRepo,
              builder: (context, _) {
                if (communityRepo.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (communityRepo.errorMessage != null) {
                  return _ErrorState(
                    message: communityRepo.errorMessage!,
                    onRetry: communityRepo.init,
                  );
                }
                final posts = communityRepo.posts(
                  area: _area,
                  category: _category,
                );

                if (posts.isEmpty) {
                  return _EmptyState(
                    onPost: _openCreatePost,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 24,
                  ),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final post = posts[index];

                    return PostCard(
                      post: post,
                      onTap: () => _openPostDetail(post),
                      onComment: () => _openPostDetail(post, focusReply: true),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Suburb? area;
  final CrimeCategory? category;
  final VoidCallback onPost;
  final VoidCallback onAreaTap;
  final ValueChanged<CrimeCategory?> onCategory;

  const _Header({
    required this.area,
    required this.category,
    required this.onPost,
    required this.onAreaTap,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) {
    final categories = communityRepo.categories;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.heroBlue,
            AppColors.darkBlue,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20, 12, 20, 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bulletin Board',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (MessagingRepository.isAvailable)
                    IconButton(
                      tooltip: 'Messages',
                      icon: const Icon(Icons.mail_outline, color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InboxScreen()),
                      ),
                    ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onPost,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Post',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onAreaTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        area?.label ?? 'All areas',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _FilterChip(
                        label: 'All',
                        selected: category == null,
                        onTap: () => onCategory(null),
                      );
                    }

                    final item = categories[index - 1];

                    return _FilterChip(
                      label: item.name,
                      selected: category == item,
                      onTap: () => onCategory(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.white
          : Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppColors.darkBlue
                  : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onPost;

  const _EmptyState({required this.onPost});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            const Text(
              'No posts here yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Be the first to post in this area.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              onPressed: onPost,
              child: const Text('Create post'),
            ),
          ],
        ),
      ),
    );
  }
}