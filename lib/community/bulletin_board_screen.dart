import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'community_data.dart';
import 'create_post_screen.dart';
import 'post_card.dart';
import 'post_detail_screen.dart';
import '../components/BottomNav/bottom_nav_scaffold.dart';

class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> {
  Suburb? _area; // null = all areas
  PostCategory? _category; // null = All

  SupabaseCommunityRepository? get _remoteRepo =>
      communityRepo is SupabaseCommunityRepository
          ? communityRepo as SupabaseCommunityRepository
          : null;

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen(initialArea: _area)),
    );
  }

  void _openAreaPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

  @override
  Widget build(BuildContext context) {
    return BottomNavScaffold(
      currentIndex: 3,
      title: 'SafeSense',
      child: Column(
        children: [
          _Header(
            area: _area,
            category: _category,
            onPost: _openCreatePost,
            onAreaTap: _openAreaPicker,
            onCategory: (c) => setState(() => _category = c),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: communityRepo,
              builder: (context, _) {
                final posts =
                    communityRepo.posts(area: _area, category: _category);
                final repo = _remoteRepo;
                if (repo?.isLoadingPosts == true && posts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (repo?.postsError != null && posts.isEmpty) {
                  return _LoadError(
                    message: repo!.postsError!,
                    onRetry: repo.refresh,
                  );
                }
                if (posts.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: repo?.refresh ?? () async {},
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.45,
                          child: _EmptyState(onPost: _openCreatePost),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: repo?.refresh ?? () async {},
                  child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final post = posts[i];
                    return PostCard(
                      post: post,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PostDetailScreen(post: post)),
                      ),
                    );
                  },
                  ),
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
          colors: [AppColors.heroBlue, AppColors.darkBlue],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bulletin Board',
                        style: TextStyle(
                        color: Colors.white,
                        fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) - 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onPost,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Post',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
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
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_outlined,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        area?.label ?? 'All areas',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70),
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
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _FilterChip(
                        label: 'All',
                        selected: category == null,
                        onTap: () => onCategory(null),
                      );
                    }
                    final c = categories[i - 1];
                    return _FilterChip(
                      label: c.chipLabel,
                      selected: category == c,
                      onTap: () => onCategory(c),
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
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.darkBlue : Colors.white,
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
            const Icon(Icons.forum_outlined,
                size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            const Text('No posts here yet',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Be the first to post in this area.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue),
              onPressed: onPost,
              child: const Text('Create post'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}

class _AreaPickerSheet extends StatefulWidget {
  final Suburb? selected;
  final ValueChanged<Suburb?> onSelected;

  const _AreaPickerSheet({required this.selected, required this.onSelected});

  @override
  State<_AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<_AreaPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = communityRepo is SupabaseCommunityRepository
        ? communityRepo as SupabaseCommunityRepository
        : null;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  autofocus: false,
                  decoration: const InputDecoration(
                    hintText: 'Search town, suburb or province',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: communityRepo,
                  builder: (context, _) {
                    final groups = <City>[];
                    for (final city in communityRepo.cities) {
                      final matches = city.suburbs.where((area) =>
                          area.name.toLowerCase().contains(_query) ||
                          area.city.toLowerCase().contains(_query) ||
                          city.name.toLowerCase().contains(_query)).toList();
                      if (matches.isNotEmpty) groups.add(City(city.name, matches));
                    }
                    return ListView(
                      children: [
                        if (_query.isEmpty)
                          ListTile(
                            leading: const Icon(Icons.public),
                            title: const Text('All areas'),
                            trailing: widget.selected == null
                                ? const Icon(Icons.check, color: AppColors.primaryBlue)
                                : null,
                            onTap: () => widget.onSelected(null),
                          ),
                        if (repo?.isLoadingAreas == true)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (repo?.areasError != null)
                          ListTile(
                            leading: const Icon(Icons.warning_amber_outlined),
                            title: Text(repo!.areasError!),
                            subtitle: const Text('Showing available fallback locations.'),
                            trailing: TextButton(
                              onPressed: repo.loadAreas,
                              child: const Text('Retry'),
                            ),
                          ),
                        if (groups.isEmpty && repo?.isLoadingAreas != true)
                          const ListTile(title: Text('No matching locations found')),
                        for (final city in groups)
                          ExpansionTile(
                            key: ValueKey('${city.name}:$_query'),
                            initiallyExpanded: _query.isNotEmpty ||
                                widget.selected?.city == city.name,
                            leading: const Icon(Icons.location_city),
                            title: Text(city.name),
                            children: [
                              for (final area in city.suburbs)
                                ListTile(
                                  contentPadding: const EdgeInsets.only(left: 56, right: 16),
                                  title: Text(area.name),
                                  subtitle: Text(area.city),
                                  trailing: widget.selected?.id == area.id
                                      ? const Icon(Icons.check, color: AppColors.primaryBlue)
                                      : null,
                                  onTap: () => widget.onSelected(area),
                                ),
                            ],
                          ),
                      ],
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
