import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/saps/saps_auth_service.dart';
import '../../services/saps/saps_case.dart';
import '../../services/saps/saps_case_service.dart';
import 'saps_colors.dart';
import 'widgets/case_detail.dart';
import 'widgets/case_list.dart';
import 'widgets/close_reason_dialog.dart';
import 'widgets/shield_mark.dart';

/// The officer's working screen: queue on the left, case on the right.
/// On a narrow screen the queue is full width and a case opens on top.
class SapsCaseDeskScreen extends StatefulWidget {
  const SapsCaseDeskScreen({super.key, required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  State<SapsCaseDeskScreen> createState() => _SapsCaseDeskScreenState();
}

class _SapsCaseDeskScreenState extends State<SapsCaseDeskScreen> {
  final _svc = SapsCaseService.instance;
  final _player = AudioPlayer();

  CaseBucket _bucket = CaseBucket.needsAction;
  String? _selectedId;
  String? _flashId;
  SapsCase? _banner;
  OfficerProfile? _officer;

  StreamSubscription<SapsCase>? _sosSub;
  Timer? _tick;
  Timer? _bannerTimer;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _svc.start();
    _sosSub = _svc.newSosAlerts.listen(_onNewSos);
    // Re-draw every 30 s so "waiting" times and Overdue badges stay true.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    SapsAuthService.instance.profile().then((p) {
      if (mounted) setState(() => _officer = p);
    });
  }

  @override
  void dispose() {
    _sosSub?.cancel();
    _tick?.cancel();
    _bannerTimer?.cancel();
    _flashTimer?.cancel();
    _player.dispose();
    _svc.stop();
    super.dispose();
  }

  // ---- live alerts ----------------------------------------------------

  Future<void> _onNewSos(SapsCase c) async {
    if (!mounted) return;
    setState(() {
      _banner = c;
      _flashId = c.id;
    });
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _banner = null);
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _flashId = null);
    });
    try {
      // Browsers only allow sound after the officer has clicked once
      // (signing in counts), so this works on a real shift.
      await _player.play(AssetSource('sounds/alert.wav'));
    } catch (_) {}
  }

  void _viewBanner() {
    final c = _banner;
    if (c == null) return;
    setState(() {
      _bucket = CaseBucket.needsAction;
      _selectedId = c.id;
      _banner = null;
    });
    _svc.logOpened(c);
  }

  // ---- actions --------------------------------------------------------

  void _snack(String text, {VoidCallback? onUndo}) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
      content: Text(text),
      duration: Duration(seconds: onUndo == null ? 4 : 7),
      behavior: SnackBarBehavior.floating,
      backgroundColor: SapsColors.navy,
      action: onUndo == null
          ? null
          : SnackBarAction(
              label: 'Undo',
              textColor: SapsColors.goldLight,
              onPressed: onUndo,
            ),
    ));
  }

  Future<void> _change(SapsCase c, String to, String message,
      {String? reason}) async {
    final from = c.status;
    try {
      await _svc.setStatus(c, to, reason: reason);
    } catch (_) {
      if (mounted) {
        _snack("Couldn't update this case. Check your connection and try again.");
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _bucket = c.bucketOf(to);
      _selectedId = c.id;
    });
    _snack(message, onUndo: () async {
      try {
        await _svc.setStatus(c, from, reason: 'Undo');
        if (!mounted) return;
        setState(() {
          _bucket = c.bucketOf(from);
          _selectedId = c.id;
        });
      } catch (_) {
        if (mounted) _snack("Couldn't undo. Check your connection.");
      }
    });
  }

  Future<void> _advance(SapsCase c) async {
    final next = c.nextStatus;
    if (next == null) return;
    await _change(c, next, 'Marked ${statusLabel(next).toLowerCase()}.');
  }

  Future<void> _closeNegative(SapsCase c) async {
    final reason = await askCloseReason(context, c);
    if (reason == null || !mounted) return;
    await _change(
      c,
      c.rejectStatus,
      'Case closed as ${statusLabel(c.rejectStatus).toLowerCase()}.',
      reason: reason,
    );
  }

  Future<void> _call(SapsCase c) async {
    final phone = c.reporterPhone;
    if (phone == null || phone.isEmpty) {
      _snack('No phone number is on file for this reporter.');
      return;
    }
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && mounted) _snack("Couldn't start the call on this device.");
  }

  Future<void> _maps(SapsCase c) async {
    if (!c.hasLocation) {
      _snack('This case has no location.');
      return;
    }
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${c.lat},${c.lng}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack("Couldn't open Maps.");
  }

  // ---- list helpers ---------------------------------------------------

  List<SapsCase> _visible(List<SapsCase> all) {
    final l = all.where((c) => c.bucket == _bucket).toList();
    l.sort((a, b) {
      if (_bucket == CaseBucket.closed) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (a.isSos != b.isSos) return a.isSos ? -1 : 1; // SOS first
      return a.createdAt.compareTo(b.createdAt); // longest waiting first
    });
    return l;
  }

  Map<CaseBucket, int> _counts(List<SapsCase> all) => {
        for (final b in CaseBucket.values)
          b: all.where((c) => c.bucket == b).length,
      };

  SapsCase? _find(List<SapsCase> l, String? id) {
    if (id == null) return null;
    for (final c in l) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _select(SapsCase c, {required bool wide}) {
    setState(() => _selectedId = c.id);
    _svc.logOpened(c);
    if (!wide) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => _NarrowDetail(id: c.id, desk: this),
      ));
    }
  }

  // ---- build ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SapsColors.background,
      body: Column(
        children: [
          _header(),
          if (_banner != null) _bannerBar(_banner!),
          ValueListenableBuilder<String?>(
            valueListenable: _svc.loadError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Container(
                    width: double.infinity,
                    color: SapsColors.goldTint,
                    padding: const EdgeInsets.all(10),
                    child: Text(err,
                        style: const TextStyle(color: SapsColors.goldText)),
                  ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<SapsCase>>(
              valueListenable: _svc.cases,
              builder: (context, all, _) {
                final visible = _visible(all);
                final counts = _counts(all);
                return LayoutBuilder(builder: (context, box) {
                  final wide = box.maxWidth >= 820;
                  final selected =
                      _find(visible, _selectedId) ?? (visible.isEmpty ? null : visible.first);
                  final list = CaseList(
                    cases: visible,
                    counts: counts,
                    bucket: _bucket,
                    onBucket: (b) => setState(() {
                      _bucket = b;
                      _selectedId = null;
                    }),
                    selectedId: selected?.id,
                    flashId: _flashId,
                    showSelection: wide,
                    onSelect: (c) => _select(c, wide: wide),
                  );
                  if (!wide) return list;
                  return Row(
                    children: [
                      SizedBox(
                        width: 380,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: SapsColors.surface,
                            border: Border(
                                right: BorderSide(color: SapsColors.border)),
                          ),
                          child: list,
                        ),
                      ),
                      Expanded(
                        child: selected == null
                            ? const Center(
                                child: Text('Select a case to see its details.',
                                    style: TextStyle(
                                        color: SapsColors.textSecondary)))
                            : ColoredBox(
                                color: SapsColors.surface,
                                child: _detail(selected),
                              ),
                      ),
                    ],
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(SapsCase c) => CaseDetail(
        key: ValueKey(c.id),
        c: c,
        onAdvance: () => _advance(c),
        onCloseNegative: () => _closeNegative(c),
        onCall: () => _call(c),
        onMaps: () => _maps(c),
      );

    Widget _header() {
    String two(int n) => n.toString().padLeft(2, '0');

    final liveStatus = ValueListenableBuilder<bool>(
      valueListenable: _svc.connected,
      builder: (_, live, _) => ValueListenableBuilder<DateTime?>(
        valueListenable: _svc.lastUpdated,
        builder: (_, at, _) {
          final t = at == null
              ? ''
              : ' · updated ${two(at.hour)}:${two(at.minute)}';
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle,
                  size: 10,
                  color: live ? const Color(0xFF6FE3A0) : SapsColors.gold),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  live ? 'Live$t' : 'Reconnecting…$t',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: SapsColors.goldLight, fontSize: 13),
                ),
              ),
            ],
          );
        },
      ),
    );

    final officer = _officer == null
        ? const SizedBox.shrink()
        : Text(
            [
              _officer!.name,
              if (_officer!.station != null) _officer!.station!,
            ].join(' · '),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(color: SapsColors.goldLight, fontSize: 13),
          );

    final signOut = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 40),
      ),
      onPressed: widget.onSignOut,
      child: const Text('Sign out'),
    );

    const title = Text('Case desk',
        style: TextStyle(
            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: SapsColors.blue,
        border: Border(bottom: BorderSide(color: SapsColors.gold, width: 3)),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, box) {
          if (box.maxWidth >= 640) {
            return Row(
              children: [
                const ShieldMark(size: 28),
                const SizedBox(width: 10),
                title,
                const SizedBox(width: 14),
                Flexible(child: liveStatus),
                const Spacer(),
                Flexible(child: officer),
                const SizedBox(width: 8),
                signOut,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShieldMark(size: 28),
                  const SizedBox(width: 10),
                  title,
                  const Spacer(),
                  signOut,
                ],
              ),
              Row(
                children: [
                  Flexible(child: liveStatus),
                  const SizedBox(width: 12),
                  Expanded(child: officer),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
  Widget _bannerBar(SapsCase c) => Container(
        width: double.infinity,
        color: SapsColors.red,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'New SOS${c.area != null ? ' in ${c.area}' : ''} · just now',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: SapsColors.redText,
                minimumSize: const Size(0, 36),
              ),
              onPressed: _viewBanner,
              child: const Text('View'),
            ),
            IconButton(
              tooltip: 'Dismiss',
              color: Colors.white,
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _banner = null),
            ),
          ],
        ),
      );
}

/// Case page used on narrow screens (phone or small window).
class _NarrowDetail extends StatelessWidget {
  const _NarrowDetail({required this.id, required this.desk});
  final String id;
  final _SapsCaseDeskScreenState desk;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SapsColors.surface,
      appBar: AppBar(
        backgroundColor: SapsColors.blue,
        foregroundColor: Colors.white,
        title: const Text('Case'),
      ),
      body: ValueListenableBuilder<List<SapsCase>>(
        valueListenable: desk._svc.cases,
        builder: (context, all, _) {
          final c = desk._find(all, id);
          if (c == null) {
            return const Center(child: Text('This case is no longer available.'));
          }
          return desk._detail(c);
        },
      ),
    );
  }
}
