import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/saps/saps_auth_service.dart';
import 'saps_case_desk_screen.dart';
import 'saps_colors.dart';
import 'saps_login_screen.dart';
import 'widgets/idle_guard.dart';

enum _Stage { checking, login, desk }

/// Decides what to show: login or case desk. The desk is only built after
/// the officer check passes (and, if set up, the verification code).
class SapsGate extends StatefulWidget {
  const SapsGate({super.key});

  @override
  State<SapsGate> createState() => _SapsGateState();
}

class _SapsGateState extends State<SapsGate> {
  _Stage _stage = _Stage.checking;
  String? _notice;
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _check();
    _sub = SapsAuthService.instance.signedOut.listen((_) {
      if (mounted) setState(() => _stage = _Stage.login);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final ok = await SapsAuthService.instance.isFullyAuthorised();
    if (!mounted) return;
    setState(() => _stage = ok ? _Stage.desk : _Stage.login);
  }

  Future<void> _signOut({String? notice}) async {
    setState(() => _notice = notice);
    await SapsAuthService.instance.signOut();
    if (mounted) setState(() => _stage = _Stage.login);
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.checking:
        return const Scaffold(
          backgroundColor: SapsColors.blue,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      case _Stage.login:
        return SapsLoginScreen(
          notice: _notice,
          onAuthorised: () => setState(() {
            _notice = null;
            _stage = _Stage.desk;
          }),
        );
      case _Stage.desk:
        return IdleGuard(
          onTimeout: () => _signOut(
              notice: 'You were signed out after 10 minutes of inactivity.'),
          child: SapsCaseDeskScreen(onSignOut: () => _signOut()),
        );
    }
  }
}
