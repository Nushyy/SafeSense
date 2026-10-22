
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../services/profile_repository.dart';
import '../../components/BottomNav/bottom_nav_scaffold.dart';

import 'edit_profile_screen.dart';
import 'personal_details_screen.dart';
import 'notifications_screen.dart';
import 'privacy_safety_screen.dart';
import 'trusted_circle_screen.dart';
import 'emergency_contacts_screen.dart';
import 'about_safesense_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  bool _reportsLoading = true;

  String _fullName = 'SafeSense User';
  String _username = '@user';
  String _town = 'Location not set';

  int _reportsCount = 0;

  // Connect this to the real alerts data once the alerts table/schema is confirmed.
  final int _alertsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadReportsCount();
  }

  Future<void> _loadReportsCount() async {
    if (!mounted) return;

    setState(() {
      _reportsLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _reportsCount = 0;
          _reportsLoading = false;
        });
        return;
      }

      // SafeSense stores submitted reports in `crime_reports`.
      final reports = await supabase
          .from('crime_reports')
          .select('id')
          .eq('user_id', user.id);

      if (!mounted) return;
      setState(() {
        _reportsCount = reports.length;
      });
    } catch (error) {
      debugPrint('Could not load report count: $error');
    } finally {
      if (mounted) {
        setState(() {
          _reportsLoading = false;
        });
      }
    }
  }

  Future<void> _refreshProfile() async {
    await Future.wait([
      _loadProfile(),
      _loadReportsCount(),
    ]);
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }

    try {
      final profile = await ProfileRepository.loadCurrentProfile();
      if (!mounted) return;

      setState(() {
        _fullName = profile.fullName.trim().isNotEmpty
            ? profile.fullName.trim()
            : 'SafeSense User';
        _username = profile.displayUsername;
        _town = profile.neighborhood.trim().isNotEmpty
            ? profile.neighborhood.trim()
            : 'Location not set';
      });
    } catch (error) {
      debugPrint('Could not load SafeSense profile: $error');

      if (mounted) {
        setState(() {
          _loadFailed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'Could not load your profile. Check your connection and database setup.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String get _initials {
    final parts = _fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'S';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text(
          'Are you sure you want to log out of SafeSense?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      // Clear the authenticated screen stack and return to login.
      context.go('/login');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not log out: $error'),
        ),
      );
    }
  }

  Future<void> _open(
    BuildContext context,
    Widget screen,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (mounted) {
      await _refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

        return BottomNavScaffold(
          currentIndex: 4,
          title: 'Profile',
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(context),
              if (_loading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_loadFailed && !_loading) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry loading profile'),
                ),
              ],
              const SizedBox(height: 20),
              _buildStats(context),
              const SizedBox(height: 28),

              _sectionHeading(context, 'ACCOUNT'),
              const SizedBox(height: 12),

              _menuCard(context, [
                _menuItem(
                  context,
                  icon: Icons.person_outline,
                  iconColor: const Color(0xFF1976D2),
                  title: 'Personal Details',
                  subtitle: 'View your registered account information',
                  onTap: () => _open(
                    context,
                    const PersonalDetailsScreen(),
                  ),
                ),
                _divider(context),
                _menuItem(
                  context,
                  icon: Icons.people_alt_outlined,
                  iconColor: const Color(0xFF00897B),
                  title: 'Trusted Circle',
                  subtitle: 'Manage people you trust',
                  onTap: () => _open(
                    context,
                    const TrustedCircleScreen(),
                  ),
                ),
                _divider(context),
                _menuItem(
                  context,
                  icon: Icons.contact_phone_outlined,
                  iconColor: const Color(0xFFE53935),
                  title: 'Emergency Contacts',
                  subtitle: 'Manage your emergency contacts',
                  onTap: () => _open(
                    context,
                    const EmergencyContactsScreen(),
                  ),
                ),
              ]),

              const SizedBox(height: 28),
              _sectionHeading(context, 'APP SETTINGS'),
              const SizedBox(height: 12),

              _menuCard(context, [
                _menuItem(
                  context,
                  icon: Icons.notifications_none_outlined,
                  iconColor: const Color(0xFFF57C00),
                  title: 'Notifications',
                  subtitle: 'Manage your SafeSense alerts',
                  onTap: () => _open(
                    context,
                    const NotificationsScreen(),
                  ),
                ),
                _divider(context),
                _menuItem(
                  context,
                  icon: Icons.security_outlined,
                  iconColor: const Color(0xFF3949AB),
                  title: 'Privacy & Safety',
                  subtitle: 'Manage privacy and safety settings',
                  onTap: () => _open(
                    context,
                    const PrivacySafetyScreen(),
                  ),
                ),
                _divider(context),
                _menuItem(
                  context,
                  icon: Icons.info_outline,
                  iconColor: const Color(0xFF039BE5),
                  title: 'About SafeSense',
                  subtitle: 'Learn more about SafeSense',
                  onTap: () => _open(
                    context,
                    const AboutSafeSenseScreen(),
                  ),
                ),
              ]),

              const SizedBox(height: 28),

              InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_outlined,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'SafeSense • Version 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
          ),
      ),
    );
  }
  

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkBlue,
            AppColors.primaryBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _username,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _town,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _open(
                context,
                const EditProfileScreen(),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.report_outlined,
            iconColor: const Color(0xFF1976D2),
            value: _reportsLoading ? '…' : _reportsCount.toString(),
            label: 'Reports',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.notifications_none_outlined,
            iconColor: const Color(0xFFF57C00),
            value: _alertsCount.toString(),
            label: 'Alerts',
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(BuildContext context, String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context,
    List<Widget> children,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      thickness: 1,
      indent: 74,
      endIndent: 16,
      color: colors.outlineVariant.withValues(alpha: 0.45),
    );
  }


}
