
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _cellphoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _stationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _accountType = 'citizen';

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isRegistering = false;

  bool get _hasMinimumLength =>
      _passwordController.text.length >= 8;

  bool get _hasUppercase =>
      RegExp(r'[A-Z]').hasMatch(_passwordController.text);

  bool get _hasLowercase =>
      RegExp(r'[a-z]').hasMatch(_passwordController.text);

  bool get _hasNumber =>
      RegExp(r'[0-9]').hasMatch(_passwordController.text);

  bool get _hasSymbol =>
      RegExp(r'[^A-Za-z0-9\s]').hasMatch(_passwordController.text);

  Widget _passwordRule(String label, bool satisfied) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 18,
            color: satisfied
                ? Colors.green.shade700
                : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (_isRegistering || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isRegistering = true);

    final fullName =
        '${_nameController.text.trim()} ${_surnameController.text.trim()}';

    final cellphone = _cellphoneController.text.trim();
    final email = _emailController.text.trim();
    final city = _cityController.text.trim();
    final password = _passwordController.text;
    final isSaps = _accountType == 'saps';

    try {
      final client = Supabase.instance.client;

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': cellphone,
          'neighborhood': city,
        },
      );

      if (!mounted) return;

      if (response.user == null) {
        throw StateError('Registration did not return a user.');
      }

      if (isSaps) {
        if (response.session != null) {
          await client.rpc(
            'submit_saps_application',
            params: {
              'p_station_name': _stationController.text.trim(),
            },
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'SAPS application submitted successfully. '
                'Your account is awaiting Administrator approval.',
              ),
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Please confirm your email '
                'and sign in to complete your SAPS application.',
              ),
              duration: Duration(seconds: 6),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful. Please check your '
              'email if confirmation is required.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account registration or SAPS application issue: '
            '${error.message}',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (error) {
      debugPrint('SafeSense registration error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please check your '
            'account status before trying again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _cellphoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _stationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create your SafeSense account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Join your community and help make it safer.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Account Type
                  DropdownButtonFormField<String>(
                    initialValue: _accountType,
                    decoration: const InputDecoration(
                      labelText: 'Register As',
                      prefixIcon:
                          Icon(Icons.account_circle_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'citizen',
                        child: Text('Citizen'),
                      ),
                      DropdownMenuItem(
                        value: 'saps',
                        child: Text('SAPS Officer'),
                      ),
                    ],
                    onChanged: _isRegistering
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _accountType = value;
                              });
                            }
                          },
                  ),

                  const SizedBox(height: 16),

                  // Police Station
                  if (_accountType == 'saps') ...[
                    TextFormField(
                      controller: _stationController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Police Station',
                        hintText: 'Enter your police station',
                        prefixIcon:
                            Icon(Icons.local_police_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_accountType == 'saps' &&
                            (value == null ||
                                value.trim().isEmpty)) {
                          return 'Please enter your police station';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'SAPS Officer registration requires '
                      'Administrator verification and approval '
                      'before access is granted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],

                  // Name
                  TextFormField(
                    controller: _nameController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your name';
                      }

                      if (value.trim().length < 2) {
                        return 'Name must contain at least 2 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Surname
                  TextFormField(
                    controller: _surnameController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Surname',
                      hintText: 'Enter your surname',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your surname';
                      }

                      if (value.trim().length < 2) {
                        return 'Surname must contain at least 2 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Cellphone
                  TextFormField(
                    controller: _cellphoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Cellphone',
                      hintText: 'e.g. 0821234567',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your cellphone number';
                      }

                      if (!RegExp(r'^0\d{9}$')
                          .hasMatch(value.trim())) {
                        return 'Enter a valid 10-digit cellphone number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your email address';
                      }

                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // City / Area
                  TextFormField(
                    controller: _cityController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'City / Area',
                      hintText: 'Enter your city or area',
                      prefixIcon:
                          Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your city or area';
                      }

                      if (value.trim().length < 2) {
                        return 'Please enter a valid city or area';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    enableSuggestions: false,
                    autocorrect: false,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Create a strong password',
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _passwordVisible
                            ? 'Hide password'
                            : 'Show password',
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible =
                                !_passwordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }

                      if (value.length < 8 ||
                          !RegExp(r'[A-Z]').hasMatch(value) ||
                          !RegExp(r'[a-z]').hasMatch(value) ||
                          !RegExp(r'[0-9]').hasMatch(value) ||
                          !RegExp(r'[^A-Za-z0-9\s]')
                              .hasMatch(value)) {
                        return 'Please meet all password requirements below';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _passwordRule(
                          'At least 8 characters',
                          _hasMinimumLength,
                        ),
                        _passwordRule(
                          'One uppercase letter (A-Z)',
                          _hasUppercase,
                        ),
                        _passwordRule(
                          'One lowercase letter (a-z)',
                          _hasLowercase,
                        ),
                        _passwordRule(
                          'One number (0-9)',
                          _hasNumber,
                        ),
                        _passwordRule(
                          'One special character (!, @, #, etc.)',
                          _hasSymbol,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller:
                        _confirmPasswordController,
                    obscureText: !_confirmPasswordVisible,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Enter your password again',
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _confirmPasswordVisible
                            ? 'Hide confirmation'
                            : 'Show confirmation',
                        icon: Icon(
                          _confirmPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _confirmPasswordVisible =
                                !_confirmPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }

                      if (value !=
                          _passwordController.text) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isRegistering ? null : _register,
                      child: Text(
                        _isRegistering
                            ? 'Registering...'
                            : _accountType == 'saps'
                                ? 'Submit SAPS Application'
                                : 'Register',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
