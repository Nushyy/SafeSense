import 'package:flutter/material.dart';
import '../messaging/inbox_screen.dart';
import '../messaging/messaging_rep.dart';
import '../theme/app_colors.dart';
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
  String? _province; // dropdown 1
  Suburb? _town; // dropdown 2 (city / town)
  Suburb? _suburb; // dropdown 3 (suburb / village)
  CrimeCategory? _category;

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(initialArea: _suburb ?? _town),
      ),
    );
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
            province: _province,
            town: _town,
            suburb: _suburb,
            category: _category,
            onPost: _openCreatePost,
            onProvince: (value) => setState(() {
              _province = value;
              _town = null;
              _suburb = null;
            }),
            onTown: (value) => setState(() {
              _town = value;
              _suburb = null;
            }),
            onSuburb: (value) => setState(() => _suburb = value),
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
                  areaIds: areaIdsFor(
                    communityRepo.areas,
                    province: _province,
                    town: _town,
                    suburb: _suburb,
                  ),
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
  final String? province;
  final Suburb? town;
  final Suburb? suburb;
  final CrimeCategory? category;
  final VoidCallback onPost;
  final ValueChanged<String?> onProvince;
  final ValueChanged<Suburb?> onTown;
  final ValueChanged<Suburb?> onSuburb;
  final ValueChanged<CrimeCategory?> onCategory;

  const _Header({
    required this.province,
    required this.town,
    required this.suburb,
    required this.category,
    required this.onPost,
    required this.onProvince,
    required this.onTown,
    required this.onSuburb,
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
              _AreaFilters(
                province: province,
                town: town,
                suburb: suburb,
                onProvince: onProvince,
                onTown: onTown,
                onSuburb: onSuburb,
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

/// Three dropdowns side by side: province, city / town, suburb / village.
class _AreaFilters extends StatelessWidget {
  final String? province;
  final Suburb? town;
  final Suburb? suburb;
  final ValueChanged<String?> onProvince;
  final ValueChanged<Suburb?> onTown;
  final ValueChanged<Suburb?> onSuburb;

  const _AreaFilters({
    required this.province,
    required this.town,
    required this.suburb,
    required this.onProvince,
    required this.onTown,
    required this.onSuburb,
  });

  @override
  Widget build(BuildContext context) {
    final areas = communityRepo.areas;
    final provinces = {
      for (final a in areas)
        if (a.province.isNotEmpty) a.province,
    }.toList()
      ..sort();
    final towns = province == null
        ? <Suburb>[]
        : (areas.where((a) => a.province == province && a.isTown).toList()
          ..sort((a, b) => a.name.compareTo(b.name)));
    final suburbs = town == null
        ? <Suburb>[]
        : (areas
            .where((a) =>
                a.province == town!.province &&
                a.isSuburbOrVillage &&
                a.city == town!.name)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)));

    return Row(
      children: [
        Expanded(
          child: _FilterDropdown<String>(
            hint: 'Province',
            allLabel: 'All provinces',
            value: province,
            items: provinces,
            labelOf: (p) => p,
            onChanged: onProvince,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterDropdown<Suburb>(
            hint: 'City / town',
            allLabel: 'All cities / towns',
            value: town,
            items: towns,
            labelOf: (a) => a.name,
            onChanged: onTown,
            enabled: province != null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterDropdown<Suburb>(
            hint: 'Suburb',
            allLabel: 'All suburbs / villages',
            value: suburb,
            items: suburbs,
            labelOf: (a) => a.name,
            onChanged: onSuburb,
            enabled: suburbs.isNotEmpty,
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String hint;
  final String allLabel;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const _FilterDropdown({
    required this.hint,
    required this.allLabel,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    const shown = TextStyle(color: Colors.white, fontSize: 13);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T?>(
            isExpanded: true,
            value: value,
            dropdownColor: AppColors.surface,
            iconEnabledColor: Colors.white,
            iconDisabledColor: Colors.white54,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            // What the closed dropdown shows (white, on the blue header).
            selectedItemBuilder: (context) => [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(hint, style: shown, overflow: TextOverflow.ellipsis),
              ),
              for (final item in items)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(labelOf(item),
                      style: shown, overflow: TextOverflow.ellipsis),
                ),
            ],
            items: [
              DropdownMenuItem<T?>(
                value: null,
                child: Text(allLabel, overflow: TextOverflow.ellipsis),
              ),
              for (final item in items)
                DropdownMenuItem<T?>(
                  value: item,
                  child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: enabled ? onChanged : null,
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