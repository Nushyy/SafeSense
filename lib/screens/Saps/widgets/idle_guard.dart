import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Signs the officer out after [limit] without a click, tap or key press.
/// The case desk shows sensitive data, so it must not stay open on an
/// unattended computer. A warning appears one minute before.
class IdleGuard extends StatefulWidget {
  const IdleGuard({
    super.key,
    required this.child,
    required this.onTimeout,
    this.limit = const Duration(minutes: 10),
  });

  final Widget child;
  final VoidCallback onTimeout;
  final Duration limit;

  @override
  State<IdleGuard> createState() => _IdleGuardState();
}

class _IdleGuardState extends State<IdleGuard> {
  Timer? _warn;
  Timer? _out;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _reset();
  }

  bool _onKey(KeyEvent _) {
    _reset();
    return false; // never swallow the key
  }

  void _reset() {
    _warn?.cancel();
    _out?.cancel();
    final warnAt = widget.limit - const Duration(minutes: 1);
    if (warnAt > Duration.zero) {
      _warn = Timer(warnAt, () {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Signing out in 1 minute because of inactivity.'),
            duration: Duration(seconds: 55),
          ));
      });
    }
    _out = Timer(widget.limit, () {
      if (mounted) widget.onTimeout();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _warn?.cancel();
    _out?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _reset(),
      onPointerMove: (_) => _reset(),
      onPointerSignal: (_) => _reset(),
      child: widget.child,
    );
  }
}
