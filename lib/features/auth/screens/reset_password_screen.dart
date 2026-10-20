import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/password_validator.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  StreamSubscription<AuthState>? _authSubscription;

  bool _isLoading = false;
  bool _isRecoveryVerified = false;
  bool _passwordUpdated = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  bool get _hasRecoveryCallback {
    if (!kIsWeb) return false;

    final uri = Uri.base;

    final parameters = <String, String>{...uri.queryParameters};

    final fragment = uri.fragment;
    final questionMark = fragment.indexOf('?');

    if (questionMark != -1) {
      parameters.addAll(
        Uri.splitQueryString(fragment.substring(questionMark + 1)),
      );
    }

    return parameters['type'] == 'recovery' ||
        parameters.containsKey('access_token') ||
        parameters.containsKey('code');
  }

  @override
  void initState() {
    super.initState();

    final auth = Supabase.instance.client.auth;

    _authSubscription = auth.onAuthStateChange.listen(
      (data) {
        if (!mounted || _passwordUpdated) return;

        if (data.event == AuthChangeEvent.passwordRecovery &&
            data.session != null) {
          setState(() {
            _isRecoveryVerified = true;
          });
        }

        if (data.event == AuthChangeEvent.signedOut) {
          setState(() {
            _isRecoveryVerified = false;
          });
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to verify the recovery session.'),
          ),
        );
      },
    );

    // A recovery callback can complete before this
    // screen subscribes to authentication events.
    //
    // Only restore access when there is a recovery
    // callback in the URL and an active session.
    if (_hasRecoveryCallback && auth.currentSession != null) {
      _isRecoveryVerified = true;
    }
  }

  Future<void> _updatePassword() async {
    if (!_isRecoveryVerified ||
        _isLoading ||
        !_formKey.currentState!.validate()) {
      return;
    }

    final auth = Supabase.instance.client.auth;

    if (auth.currentSession == null) {
      setState(() {
        _isRecoveryVerified = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await auth.updateUser(UserAttributes(password: _passwordController.text));

      await auth.signOut();

      if (!mounted) return;

      setState(() {
        _passwordUpdated = true;
        _isRecoveryVerified = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update your password. '
            'Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _passwordUpdated
              ? _buildSuccess()
              : !_isRecoveryVerified
              ? _buildVerificationRequired()
              : _buildPasswordForm(),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Password updated',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your password has been updated. '
          'You can now sign in using your new password.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          child: const Text('Go to Login'),
        ),
      ],
    );
  }

  Widget _buildVerificationRequired() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_clock_outlined, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Recovery verification required',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Open the password-reset link sent '
          'to your email. If the link has expired '
          'or is invalid, request a new one.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/forgot-password'),
          child: const Text('Request a New Link'),
        ),
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.password_outlined, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Create a new password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Use at least 8 characters, including '
            'uppercase and lowercase letters, '
            'a number, and a symbol.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'New Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: PasswordValidator.validate,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            enabled: !_isLoading,
            obscureText: _obscureConfirmation,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmation = !_obscureConfirmation;
                  });
                },
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }

              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }

              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
  }
}
