import 'package:flutter/material.dart';

import '../../services/profile_repository.dart';
import 'edit_profile_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  ProfileRecord? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ProfileRepository.loadCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _edit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _messageState(_error!, onRetry: _load)
              : profile == null
                  ? _messageState('Your profile details are not available.', onRetry: _load)
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 29,
                                backgroundColor: colors.primaryContainer,
                                child: Text(
                                  profile.initials,
                                  style: TextStyle(
                                    color: colors.onPrimaryContainer,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.fullName.isEmpty
                                          ? 'Name not set'
                                          : profile.fullName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.displayUsername,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              _detailRow(context, 'Full name', profile.fullName, Icons.person_outline),
                              _divider(context),
                              _detailRow(context, 'Username', profile.displayUsername, Icons.alternate_email),
                              _divider(context),
                              _detailRow(context, 'Phone number', _orNotSet(profile.phoneNumber), Icons.phone_outlined),
                              _divider(context),
                              _detailRow(context, 'Email address', _orNotSet(profile.email), Icons.email_outlined),
                              _divider(context),
                              _detailRow(context, 'Town / neighbourhood', _orNotSet(profile.neighborhood), Icons.location_on_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'These details are loaded from your signed-in account and SafeSense profile.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _edit,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit profile details'),
                          ),
                        ),
                      ],
                    ),
    );
  }

  String _orNotSet(String value) => value.trim().isEmpty ? 'Not set' : value;

  Widget _messageState(String message, {required VoidCallback onRetry}) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 42, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
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

  Widget _detailRow(BuildContext context, String label, String value, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}
