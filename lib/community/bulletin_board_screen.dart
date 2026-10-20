
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
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
  PostCategory? _category;

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(initialArea: _area),
      ),
    );
  }

  void _openAreaPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) => _AreaPickerSheet(
        selected: _area,
        onSelected: (area) {
          setState(() => _area = area);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _openPostDetail(dynamic post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
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
  final PostCategory? category;
  final VoidCallback onPost;
  final VoidCallback onAreaTap;
  final ValueChanged<PostCategory?> onCategory;

  const _Header({
    required this.area,
    required this.category,
    required this.onPost,
    required this.onAreaTap,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) {
    final categories = PostCategory.values;

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
                  Material(
                    color: Colors.white.withOpacity(0.15),
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
                      label: item.chipLabel,
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
          : Colors.white.withOpacity(0.14),
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

class _AreaPickerSheet extends StatelessWidget {
  final Suburb? selected;
  final ValueChanged<Suburb?> onSelected;

  const _AreaPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const check = Icon(
      Icons.check,
      color: AppColors.primaryBlue,
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Choose your area',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('All areas'),
              trailing: selected == null ? check : null,
              onTap: () => onSelected(null),
            ),
            for (final city in communityRepo.cities)
              ExpansionTile(
                initiallyExpanded:
                    selected?.city == city.name,
                leading: const Icon(Icons.location_city),
                title: Text(city.name),
                children: [
                  for (final suburb in city.suburbs)
                    ListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 72,
                        right: 16,
                      ),
                      title: Text(suburb.name),
                      trailing: selected?.id == suburb.id
                          ? check
                          : null,
                      onTap: () => onSelected(suburb),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
