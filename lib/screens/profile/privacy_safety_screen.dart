
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
  bool _deletingAccount = false;
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
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError =
              'Could not load privacy settings. Please try again.';
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
    if (_saving || _deletingAccount) return;

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
            content: Text(
              'Could not save that setting. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showDeactivationConfirmation() async {
    if (_saving || _deletingAccount) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 42,
          ),
          title: const Text('Permanently delete account?'),
          content: const Text(
            'This action cannot be undone.\n\n'
            'Your SafeSense account and profile will be permanently '
            'deleted. Your previously submitted crime reports will '
            'remain in the system.\n\n'
            'If you want to use SafeSense again, you will need to '
            'register a completely new account. Your old account '
            'cannot be restored.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _showFinalDeletionConfirmation();
  }

  Future<void> _showFinalDeletionConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Final confirmation'),
          content: const Text(
            'Are you absolutely sure you want to permanently '
            'delete your SafeSense account?\n\n'
            'You will be signed out and will need to create a '
            'new account if you return.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Go back'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete permanently'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_deletingAccount || _saving) return;

    setState(() => _deletingAccount = true);

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('No signed-in account was found.');
      }

      // Calls the server-side Supabase Edge Function.
      // The function must verify the authenticated user before deletion.
      final response = await _supabase.functions.invoke(
        'delete-account',
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception('Account deletion failed.');
      }

      // Clear the local session after successful server-side deletion.
      await _supabase.auth.signOut(
        scope: SignOutScope.local,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your SafeSense account has been deleted.'),
        ),
      );

      // The app's authentication router should now display the login screen.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not delete your account. Please try again. '
              'Details: $error',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deletingAccount = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Safety'),
      ),
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

                    const SizedBox(height: 28),
                    Divider(color: colors.outlineVariant),
                    const SizedBox(height: 20),

                    Text(
                      'ACCOUNT',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFEBEE),
                          child: Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red,
                          ),
                        ),
                        title: const Text(
                          'Deactivate Account',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            'Permanently delete your account and profile',
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.red,
                        ),
                        onTap: (_saving || _deletingAccount)
                            ? null
                            : _showDeactivationConfirmation,
                      ),
                    ),

                    if (_deletingAccount) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 10),
                      const Text(
                        'Deleting your account. Please wait...',
                        textAlign: TextAlign.center,
                      ),
                    ],
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
        onChanged: (_saving || _deletingAccount) ? null : onChanged,
      ),
    );
  }
}
