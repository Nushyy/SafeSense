
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/saps/saps_auth_service.dart';
import 'saps_case_desk_screen.dart';
import 'saps_colors.dart';
import 'widgets/idle_guard.dart';

class SapsGate extends StatefulWidget {
  const SapsGate({super.key});

  @override
  State<SapsGate> createState() => _SapsGateState();
}

class _SapsGateState extends State<SapsGate> {
  bool _checking = true;
  bool _authorised = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final authorised =
        await SapsAuthService.instance.isFullyAuthorised();

    if (!mounted) return;

    if (!authorised) {
      context.go('/account-status');
      return;
    }

    setState(() {
      _authorised = true;
      _checking = false;
    });
  }

  Future<void> _signOut() async {
    if (_signingOut) return;

    setState(() => _signingOut = true);

    try {
      await SapsAuthService.instance.signOut();

      if (!mounted) return;

      context.go('/login');
    } catch (error) {
      debugPrint('SafeSense SAPS sign-out error: $error');

      if (!mounted) return;

      setState(() => _signingOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to sign out. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || _signingOut) {
      return const Scaffold(
        backgroundColor: SapsColors.blue,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (!_authorised) {
      return const Scaffold(
        body: Center(
          child: Text('SAPS Officer access required.'),
        ),
      );
    }

    return IdleGuard(
      onTimeout: _signOut,
      child: SapsCaseDeskScreen(
        onSignOut: _signOut,
      ),
    );
  }
}
