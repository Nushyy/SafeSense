
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // STEP 1: Authenticate the user with Supabase.
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        throw Exception(
          'Unable to identify the authenticated user.',
        );
      }

      // STEP 2: Verify Administrator privileges.
      final isAdmin =
          await supabase.rpc('is_safesense_admin') == true;

      if (!mounted) return;

      // STEP 3: Administrator login.
      if (isAdmin) {
        debugPrint(
          'SafeSense: Administrator login confirmed.',
        );

        // Test Administrator access to pending Citizen profiles.
        final pendingCitizens = await supabase
            .from('profiles')
            .select(
              'id, username, full_name, approval_status',
            )
            .eq('role_id', 1)
            .eq('approval_status', 'pending');

        debugPrint(
          'SafeSense: Pending Citizens found: '
          '${pendingCitizens.length}',
        );

        if (!mounted) return;

        // Navigate to the Administrator Dashboard.
        context.go('/admin');
        return;
      }

      // STEP 4: Retrieve the user's profile.
      final profile = await supabase
          .from('profiles')
          .select('role_id, approval_status')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      // Restrict accounts without a profile.
      if (profile == null) {
        debugPrint(
          'SafeSense: User profile not found.',
        );

        context.go('/account-status');
        return;
      }

      final roleId = profile['role_id'] as int?;
      final approvalStatus =
          profile['approval_status'] as String?;

      // STEP 5: Restrict pending and rejected accounts.
      if (approvalStatus != 'approved') {
        debugPrint(
          'SafeSense: Account approval required.',
        );

        context.go('/account-status');
        return;
      }

      // STEP 6: Approved Citizen login.
      if (roleId == 1) {
        debugPrint(
          'SafeSense: Approved Citizen login.',
        );

        context.go('/home');
        return;
      }

      // STEP 7: SAPS Official login.
      if (roleId == 6) {
        final officer = await supabase
            .from('saps_officers')
            .select('verification_status')
            .eq('user_id', user.id)
            .maybeSingle();

        if (!mounted) return;

        if (officer != null &&
            officer['verification_status'] == 'verified') {
          debugPrint(
            'SafeSense: Verified SAPS Official login.',
          );

          context.go('/saps');
        } else {
          debugPrint(
            'SafeSense: SAPS verification required.',
          );

          context.go('/account-status');
        }

        return;
      }

      // STEP 8: Restrict all other roles.
      debugPrint(
        'SafeSense: No authorized dashboard for this role.',
      );

      context.go('/account-status');
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'SafeSense database error: ${error.message}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to verify your account permissions. '
            'Please try again.',
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'SafeSense login error: $error',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeSense'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_mark.png',
                  width: 220,
                  height: 180,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Sign in to continue to SafeSense.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Email address
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [
                    AutofillHints.email,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }

                    final email = value.trim();

                    final emailPattern = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailPattern.hasMatch(email)) {
                      return 'Please enter a valid email address';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  autofillHints: const [
                    AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Forgot Password navigation
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => context.push('/forgot-password'),
                    child: const Text(
                      'Forgot Password?',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Don't have an account?",
                ),

                // Registration navigation
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.push('/register'),
                  child: const Text(
                    'Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
