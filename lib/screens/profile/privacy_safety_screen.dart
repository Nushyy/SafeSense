
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool profileVisibility = false;
  bool trustedCircleLocation = true;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in to load your privacy settings.');
      }

      final data = await _supabase
          .from('user_settings')
          .select('profile_visibility, trusted_circle_location')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        setState(() {
          profileVisibility = data['profile_visibility'] as bool;
          trustedCircleLocation =
              data['trusted_circle_location'] as bool;
        });
      }
      // If no record exists yet, the default values remain in place.
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load privacy settings. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _savePreference({
    required String column,
    required bool value,
    required ValueChanged<bool> updateLocalValue,
  }) async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in to save your settings.');
      }

      await _supabase.from('user_settings').upsert(
        {
          'user_id': user.id,
          column: value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );

      if (!mounted) return;
      setState(() => updateLocalValue(value));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save that setting. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Safety')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadPreferences,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'PRIVACY SETTINGS',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _setting(
                      context,
                      title: 'Profile Visibility',
                      subtitle:
                          'Allow other community members to see your public profile',
                      value: profileVisibility,
                      onChanged: (value) => _savePreference(
                        column: 'profile_visibility',
                        value: value,
                        updateLocalValue: (savedValue) {
                          profileVisibility = savedValue;
                        },
                      ),
                    ),
                    _setting(
                      context,
                      title: 'Trusted Circle Location',
                      subtitle:
                          'Allow members of your trusted circle to receive your shared location',
                      value: trustedCircleLocation,
                      onChanged: (value) => _savePreference(
                        column: 'trusted_circle_location',
                        value: value,
                        updateLocalValue: (savedValue) {
                          trustedCircleLocation = savedValue;
                        },
                      ),
                    ),
                    if (_saving)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
    );
  }

  Widget _setting(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 7,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        value: value,
        onChanged: _saving ? null : onChanged,
      ),
    );
  }
}
