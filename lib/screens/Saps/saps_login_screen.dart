import 'package:flutter/material.dart';

import '../../services/saps/saps_auth_service.dart';
import 'saps_colors.dart';
import 'widgets/code_boxes.dart';
import 'widgets/shield_mark.dart';

enum _Step { credentials, code }

enum _Tone { bad, ok, info }

/// Officer login. There is deliberately no sign-up and no link to the
/// public app. Accounts are created by an administrator in Supabase.
class SapsLoginScreen extends StatefulWidget {
  const SapsLoginScreen({super.key, required this.onAuthorised, this.notice});

  final VoidCallback onAuthorised;

  /// Shown on arrival, e.g. "You were signed out after 10 minutes".
  final String? notice;

  @override
  State<SapsLoginScreen> createState() => _SapsLoginScreenState();
}

class _SapsLoginScreenState extends State<SapsLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _emailF = FocusNode();
  final _passF = FocusNode();
  final _codeF = FocusNode();

  _Step _step = _Step.credentials;
  bool _showPw = false;
  bool _busy = false;
  String? _emailErr;
  String? _pwErr;
  String? _codeErr;
  String? _msg;
  _Tone _tone = _Tone.info;

  // Client-side attempt counter is a courtesy to the user. The real limit
  // is enforced by Supabase (auth rate limits), not by this screen.
  int _attemptsLeft = 3;
  DateTime? _lockedUntil;

  bool get _locked =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  @override
  void initState() {
    super.initState();
    if (widget.notice != null) {
      _msg = widget.notice;
      _tone = _Tone.info;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    _emailF.dispose();
    _passF.dispose();
    _codeF.dispose();
    super.dispose();
  }

  void _say(String text, _Tone tone) {
    _msg = text;
    _tone = tone;
  }

  void _showLocked() {
    setState(() => _say(
        'Too many attempts. This account is locked for 15 minutes. '
        'Contact your station administrator if you need access sooner.',
        _Tone.bad));
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_step == _Step.code) {
      await _verifyCode();
      return;
    }

    final email = _email.text.trim();
    final emailOk = RegExp(r'^\S+@\S+\.\S+$').hasMatch(email);
    final pwOk = _password.text.isNotEmpty;

    setState(() {
      _emailErr = emailOk
          ? null
          : 'Enter your official email, like name@station.example';
      _pwErr = pwOk ? null : 'Enter your password';
      _msg = null;
    });
    if (!emailOk || !pwOk) {
      setState(() => _say('Fix the highlighted fields to continue.', _Tone.bad));
      (emailOk ? _passF : _emailF).requestFocus();
      return;
    }
    if (_locked) {
      _showLocked();
      return;
    }

    setState(() => _busy = true);
    final result = await SapsAuthService.instance.signIn(email, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case SapsSignInResult.ok:
        widget.onAuthorised();
        return;
      case SapsSignInResult.needsCode:
        setState(() {
          _step = _Step.code;
          _msg = null;
          _code.clear();
        });
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _codeF.requestFocus());
        return;
      case SapsSignInResult.badCredentials:
        setState(() => _say(
            'Email or password is incorrect. Check them and try again.',
            _Tone.bad));
        return;
      case SapsSignInResult.notAuthorised:
        setState(() =>
            _say("This account isn't authorised for the case desk.", _Tone.bad));
        return;
      case SapsSignInResult.mfaNotSetUp:
        setState(() => _say(
            'Two-step verification isn\'t set up for this account. '
            'Ask your station administrator to set it up.',
            _Tone.bad));
        return;
      case SapsSignInResult.offline:
        setState(() => _say(
            "Couldn't reach the server. Check your connection and try again.",
            _Tone.bad));
        return;
    }
  }

  Future<void> _verifyCode() async {
    if (_code.text.length < CodeBoxes.length) {
      setState(() {
        _codeErr = 'Enter all 6 digits';
        _say('Fix the highlighted fields to continue.', _Tone.bad);
      });
      _codeF.requestFocus();
      return;
    }
    if (_locked) {
      _showLocked();
      return;
    }
    setState(() {
      _busy = true;
      _codeErr = null;
    });
    final ok = await SapsAuthService.instance.verifyCode(_code.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _busy = false);
      widget.onAuthorised();
      return;
    }

    _attemptsLeft--;
    _code.clear();
    if (_attemptsLeft <= 0) {
      _lockedUntil = DateTime.now().add(const Duration(minutes: 15));
      _attemptsLeft = 3;
      await SapsAuthService.instance.signOut();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = _Step.credentials;
        _password.clear();
      });
      _showLocked();
    } else {
      setState(() {
        _busy = false;
        _say(
            "That code isn't right. Check your authenticator app and try "
            'again. $_attemptsLeft '
            '${_attemptsLeft == 1 ? 'attempt' : 'attempts'} left.',
            _Tone.bad);
      });
      _codeF.requestFocus();
    }
  }

  Future<void> _useOtherAccount() async {
    await SapsAuthService.instance.signOut();
    if (!mounted) return;
    setState(() {
      _step = _Step.credentials;
      _password.clear();
      _code.clear();
      _msg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SapsColors.blue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _header(),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _step == _Step.credentials
                            ? _credentials()
                            : _codeStep(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: const BoxDecoration(
          color: SapsColors.navy,
          border: Border(bottom: BorderSide(color: SapsColors.gold, width: 3)),
        ),
        child: const Column(
          children: [
            ShieldMark(size: 34),
            SizedBox(height: 8),
            Text('Law enforcement portal',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 2),
            Text('Authorised personnel only',
                style: TextStyle(color: SapsColors.goldLight, fontSize: 13)),
          ],
        ),
      );

  Widget _credentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Official email'),
        _field(
          controller: _email,
          focus: _emailF,
          hint: 'name@station.example',
          error: _emailErr,
          keyboard: TextInputType.emailAddress,
          autofill: const [AutofillHints.username],
          action: TextInputAction.next,
          onSubmitted: (_) => _passF.requestFocus(),
        ),
        _fieldError(_emailErr),
        const SizedBox(height: 14),
        _label('Password'),
        _field(
          controller: _password,
          focus: _passF,
          hint: 'Your password',
          error: _pwErr,
          obscure: !_showPw,
          autofill: const [AutofillHints.password],
          action: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          suffix: TextButton(
            onPressed: () => setState(() => _showPw = !_showPw),
            child: Text(_showPw ? 'Hide' : 'Show'),
          ),
        ),
        _fieldError(_pwErr),
        const SizedBox(height: 18),
        _signInButton('Sign in'),
        ..._statusBox(),
        const SizedBox(height: 14),
        const Text(
          'Accounts are created by your station administrator. Forgot your '
          'password? Ask your administrator to reset it. Access is logged.',
          style: TextStyle(
              fontSize: 13, color: SapsColors.textSecondary, height: 1.5),
        ),
        if (SapsAuthService.instance.demoHint != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SapsColors.blueTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(SapsAuthService.instance.demoHint!,
                style: const TextStyle(
                    fontSize: 13, color: SapsColors.blueTintText)),
          ),
        ],
      ],
    );
  }

  Widget _codeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('6-digit code from your authenticator app'),
        CodeBoxes(
          controller: _code,
          focusNode: _codeF,
          hasError: _codeErr != null,
          onCompleted: _submit,
        ),
        _fieldError(_codeErr),
        const SizedBox(height: 18),
        _signInButton('Verify and sign in'),
        ..._statusBox(),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _busy ? null : _useOtherAccount,
            child: const Text('Use a different account'),
          ),
        ),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3A5E))),
      );

  Widget _fieldError(String? e) => e == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline,
                  size: 16, color: SapsColors.redText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(e,
                    style: const TextStyle(
                        fontSize: 13, color: SapsColors.redText)),
              ),
            ],
          ),
        );

  Widget _field({
    required TextEditingController controller,
    required FocusNode focus,
    required String hint,
    String? error,
    bool obscure = false,
    TextInputType? keyboard,
    Iterable<String>? autofill,
    TextInputAction? action,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) {
    OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c, width: w),
        );
    final base = error != null ? SapsColors.red : SapsColors.fieldBorder;
    return TextField(
      controller: controller,
      focusNode: focus,
      obscureText: obscure,
      keyboardType: keyboard,
      autofillHints: autofill,
      textInputAction: action,
      onSubmitted: onSubmitted,
      onChanged: (_) {
        if (error != null) {
          setState(() {
            _emailErr = null;
            _pwErr = null;
          });
        }
      },
      style: const TextStyle(fontSize: 16, color: SapsColors.navy),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: suffix,
        enabledBorder: b(base, 1.5),
        focusedBorder:
            b(error != null ? SapsColors.red : SapsColors.blue, 2.5),
      ),
    );
  }

  Widget _signInButton(String label) => SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SapsColors.gold,
            foregroundColor: SapsColors.navy,
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _submit,
          child: _busy
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: SapsColors.navy),
                    ),
                    SizedBox(width: 10),
                    Text('Signing in…'),
                  ],
                )
              : Text(label),
        ),
      );

  List<Widget> _statusBox() {
    if (_msg == null) return const [];
    final bg = switch (_tone) {
      _Tone.bad => SapsColors.redTint,
      _Tone.ok => SapsColors.greenTint,
      _Tone.info => SapsColors.goldTint,
    };
    final fg = switch (_tone) {
      _Tone.bad => SapsColors.redText,
      _Tone.ok => const Color(0xFF0F4D2A),
      _Tone.info => SapsColors.goldText,
    };
    return [
      const SizedBox(height: 12),
      Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(_msg!,
              style: TextStyle(fontSize: 14, color: fg, height: 1.4)),
        ),
      ),
    ];
  }
}
