import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/trusted_circle_repository.dart';

class AddTrustedUserScreen extends StatefulWidget {
  const AddTrustedUserScreen({super.key});

  @override
  State<AddTrustedUserScreen> createState() => _AddTrustedUserScreenState();
}

class _AddTrustedUserScreenState extends State<AddTrustedUserScreen> {
  final _usernameController = TextEditingController();

  TrustedProfileMatch? _match;
  bool _searching = false;
  bool _sending = false;
  bool _searched = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _match = null;
        _searched = true;
        _message = 'Enter a username first.';
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _searching = true;
      _searched = false;
      _match = null;
      _message = null;
    });

    try {
      final match = await TrustedCircleRepository.searchUsername(username);
      if (!mounted) return;

      if (match == null) {
        setState(() {
          _searched = true;
          _message = 'No SafeSense account was found with that username. Check the spelling and try again.';
          _messageIsError = true;
        });
        return;
      }

      if (match.id == Supabase.instance.client.auth.currentUser?.id) {
        setState(() {
          _searched = true;
          _message = 'That username belongs to your own account. You cannot add yourself.';
          _messageIsError = true;
        });
        return;
      }

      setState(() {
        _match = match;
        _searched = true;
        _message = 'Account found. Confirm this is the person you want to invite.';
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searched = true;
        _message = _friendlyError(error);
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendRequest() async {
    final match = _match;
    if (match == null) return;

    setState(() {
      _sending = true;
      _message = null;
    });

    try {
      await TrustedCircleRepository.sendRequest(match.username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent to ${match.displayUsername}.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _friendlyError(error);
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('PostgrestException(message: ', '');
    if (raw.toLowerCase().contains('already sent')) {
      return 'You have already sent this person a request.';
    }
    if (raw.toLowerCase().contains('already sent you')) {
      return 'This person has already requested to join your circle. Check Incoming Requests.';
    }
    if (raw.toLowerCase().contains('already in')) {
      return 'This person is already in your Trusted Circle.';
    }
    if (raw.toLowerCase().contains('no safesense user')) {
      return 'No SafeSense account was found with that username.';
    }
    if (raw.toLowerCase().contains('cannot add yourself')) {
      return 'You cannot add your own account.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Trusted Person')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person_search_outlined, color: colors.onPrimaryContainer, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Search for an existing SafeSense username before sending a request. No request is sent until you confirm the account below.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _usernameController,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: '@username',
              prefixIcon: const Icon(Icons.alternate_email),
              suffixIcon: IconButton(
                tooltip: 'Search username',
                onPressed: _searching ? null : _search,
                icon: _searching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _searching ? null : _search,
              icon: const Icon(Icons.search),
              label: Text(_searching ? 'Searching…' : 'Search SafeSense'),
            ),
          ),
          if (_searched && _message != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _messageIsError
                    ? colors.errorContainer
                    : colors.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _messageIsError ? Icons.error_outline : Icons.check_circle_outline,
                    color: _messageIsError
                        ? colors.onErrorContainer
                        : colors.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _messageIsError
                            ? colors.onErrorContainer
                            : colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_match != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      _initials(_match!.fullName),
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _match!.fullName.trim().isEmpty
                              ? 'SafeSense user'
                              : _match!.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _match!.displayUsername,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.verified_user_outlined, color: colors.primary),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _sending ? null : _sendRequest,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: Text(_sending ? 'Sending…' : 'Send request'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
