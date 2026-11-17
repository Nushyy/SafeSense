import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

class WelcomeHeader extends StatefulWidget {
  const WelcomeHeader({super.key, this.name});

  final String? name;

  @override
  State<WelcomeHeader> createState() => _WelcomeHeaderState();
}

class _WelcomeHeaderState extends State<WelcomeHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _postsChannel;

  int _postCount = 0;
  bool _isLoadingCount = true;

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  String get _displayName {
    final name = widget.name?.trim() ?? '';
    return name.isEmpty ? '' : ', $name';
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    _initializePostCounter();
  }

  // Retrieve the total number of Bulletin Board posts.
  Future<void> _loadPostCount() async {
    try {
      final count = await _supabase
          .from('community_posts')
          .count(CountOption.exact);

      if (!mounted) return;

      setState(() {
        _postCount = count;
        _isLoadingCount = false;
      });
    } catch (error) {
      debugPrint('Unable to load Bulletin Board post count: $error');

      if (!mounted) return;

      setState(() {
        _isLoadingCount = false;
      });
    }
  }

  // Listen for posts being added or deleted.
  void _initializePostCounter() {
    _postsChannel = _supabase
        .channel('home-bulletin-post-count')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'community_posts',
          callback: (payload) {
            unawaited(_loadPostCount());
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'community_posts',
          callback: (payload) {
            unawaited(_loadPostCount());
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            unawaited(_loadPostCount());
          }

          if (status == RealtimeSubscribeStatus.channelError) {
            debugPrint('Bulletin Board Realtime subscription error: $error');
          }
        });

    // Load the initial count even if Realtime is unavailable.
    unawaited(_loadPostCount());
  }

  @override
  void dispose() {
    final channel = _postsChannel;

    if (channel != null) {
      unawaited(_supabase.removeChannel(channel));
    }

    _controller.dispose();
    super.dispose();
  }

  Widget _notificationBell() {
    return IconButton(
      tooltip: 'Bulletin Board',
      onPressed: () {
        context.go('/alerts');
      },
      icon: Badge(
        isLabelVisible: !_isLoadingCount && _postCount > 0,
        label: Text(_postCount > 99 ? '99+' : '$_postCount'),
        child: const Icon(
          Icons.notifications_outlined,
          color: AppColors.navy,
          size: 27,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_greeting$_displayName!',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        height: 1.25,
                      ),
                    ),
                  ),
                  _notificationBell(),
                ],
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                'Stay connected. Stay aware. Stay safe.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
