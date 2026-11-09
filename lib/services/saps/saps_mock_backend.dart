import 'dart:async';

import 'saps_auth_service.dart';
import 'saps_case.dart';
import 'saps_case_service.dart';

/// DEMO ONLY. Fake login and fake cases so the screens work with no server.
/// Nothing here is secure and none of the data is real.
class MockSapsAuth extends SapsAuthService {
  final StreamController<void> _out = StreamController<void>.broadcast();
  bool _pendingCode = false;
  bool _signedIn = false;

  static const demoEmail = 'officer@station.example';
  static const demoPassword = 'saps1234';
  static const demoCode = '123456';

  @override
  Stream<void> get signedOut => _out.stream;

  @override
  String? get demoHint =>
      'Demo only: $demoEmail · $demoPassword · code $demoCode';

  @override
  Future<SapsSignInResult> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final e = email.trim().toLowerCase();
    if (e == demoEmail && password == demoPassword) {
      _pendingCode = true;
      return SapsSignInResult.needsCode;
    }
    if (e.contains('citizen')) return SapsSignInResult.notAuthorised;
    return SapsSignInResult.badCredentials;
  }

  @override
  Future<bool> verifyCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_pendingCode && code == demoCode) {
      _pendingCode = false;
      _signedIn = true;
      return true;
    }
    return false;
  }

  @override
  Future<bool> isFullyAuthorised() async => _signedIn;

  @override
  Future<OfficerProfile> profile() async =>
      const OfficerProfile(name: 'Sgt. M. Dlamini', station: 'Soweto');

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _pendingCode = false;
    _out.add(null);
  }
}

class MockSapsCases extends SapsCaseService {
  final List<SapsCase> _all = [];
  final Map<String, List<AuditEntry>> _audit = {};
  bool _started = false;
  int _counter = 0;
  int _simulated = 0;
  Timer? _first;
  Timer? _more;

  static const _areas = ['Zola', 'Protea Glen', 'Pimville', 'Mofolo', 'Naledi'];

  DateTime _ago(int minutes) =>
      DateTime.now().subtract(Duration(minutes: minutes));

  void _seed() {
    _all
      ..clear()
      ..addAll([
        SapsCase(
          id: 'demo-1',
          kind: CaseKind.sos,
          title: 'SOS alert',
          area: 'Orlando East',
          lat: -26.2358,
          lng: 27.9231,
          status: 'active',
          createdAt: _ago(2),
          description: 'Live location shared.',
          reporterName: 'Thabo M.',
          reporterPhone: '+27 11 555 0101',
          battery: 64,
        ),
        SapsCase(
          id: 'demo-2',
          kind: CaseKind.report,
          title: 'Armed robbery',
          area: 'Jabulani Mall',
          lat: -26.2400,
          lng: 27.8650,
          status: 'pending',
          createdAt: _ago(18),
          description: '2 photos attached. 3 community confirmations.',
        ),
        SapsCase(
          id: 'demo-3',
          kind: CaseKind.report,
          title: 'Vehicle break-in',
          area: 'Meadowlands',
          lat: -26.2230,
          lng: 27.8880,
          status: 'pending',
          createdAt: _ago(44),
          description: 'No photos. 1 community confirmation.',
          reporterName: 'Lerato K.',
          reporterPhone: '+27 11 555 0102',
        ),
        SapsCase(
          id: 'demo-4',
          kind: CaseKind.sos,
          title: 'SOS alert',
          area: 'Dube',
          lat: -26.2330,
          lng: 27.8760,
          status: 'responding',
          createdAt: _ago(9),
          description: 'Unit 14 dispatched. ETA 4 min.',
          reporterName: 'Sipho N.',
          reporterPhone: '+27 11 555 0103',
          battery: 41,
        ),
        SapsCase(
          id: 'demo-5',
          kind: CaseKind.report,
          title: 'Suspicious activity',
          area: 'Diepkloof',
          lat: -26.2560,
          lng: 27.9000,
          status: 'resolved',
          createdAt: _ago(600),
          description: 'Patrol checked the area. No incident found.',
        ),
      ]);
  }

  void _publish() {
    cases.value = List<SapsCase>.of(_all);
    lastUpdated.value = DateTime.now();
  }

  void _newSos() {
    final area = _areas[_simulated % _areas.length];
    _simulated++;
    _counter++;
    final c = SapsCase(
      id: 'demo-new-$_counter',
      kind: CaseKind.sos,
      title: 'SOS alert',
      area: area,
      lat: -26.25 - _simulated * 0.004,
      lng: 27.85 + _simulated * 0.006,
      status: 'active',
      createdAt: DateTime.now(),
      description: 'Live location shared.',
      reporterName: 'New user',
      reporterPhone: '+27 11 555 0199',
      battery: 80,
    );
    _all.add(c);
    _publish();
    announceNewSos(c);
  }

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _seed();
    connected.value = true;
    loadError.value = null;
    _publish();
    // Demo: a new SOS arrives after 8 s, then two more, 40 s apart.
    _first = Timer(const Duration(seconds: 8), () {
      _newSos();
      _more = Timer.periodic(const Duration(seconds: 40), (t) {
        if (_simulated >= 3) {
          t.cancel();
          return;
        }
        _newSos();
      });
    });
  }

  @override
  Future<void> stop() async {
    _started = false;
    _first?.cancel();
    _more?.cancel();
    connected.value = false;
    cases.value = const [];
    lastUpdated.value = null;
  }

  @override
  Future<void> refresh() async => _publish();

  @override
  Future<void> setStatus(SapsCase c, String status, {String? reason}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final i = _all.indexWhere((x) => x.id == c.id);
    if (i < 0) return;
    _all[i] = _all[i].copyWith(status: status);
    (_audit[c.id] ??= []).insert(
      0,
      AuditEntry(
        action: 'status:$status',
        officer: 'Sgt. M. Dlamini',
        at: DateTime.now(),
        reason: reason,
      ),
    );
    _publish();
  }

  @override
  Future<void> logOpened(SapsCase c) async {
    final list = _audit[c.id] ??= [];
    final already = list.any((e) => e.action == 'opened');
    if (already) return;
    list.insert(
      0,
      AuditEntry(
        action: 'opened',
        officer: 'Sgt. M. Dlamini',
        at: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<AuditEntry>> audit(SapsCase c) async =>
      List<AuditEntry>.of(_audit[c.id] ?? const []);
}
