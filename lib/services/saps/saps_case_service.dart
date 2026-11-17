import 'dart:async';

import 'package:flutter/foundation.dart';

import 'saps_case.dart';

class AuditEntry {
  const AuditEntry({
    required this.action,
    required this.officer,
    required this.at,
    this.reason,
  });

    /// 'opened' or 'status:NEW_STATUS' (for example 'status:responding').
  final String action;
  final String officer;
  final DateTime at;
  final String? reason;

  String get text {
    if (action == 'opened') return 'Opened';
    if (action.startsWith('status:')) {
      return 'Set to ${statusLabel(action.substring(7))}';
    }
    return action;
  }
}

/// What the case desk needs from the backend.
///
/// The screens only talk to this class. `main_saps.dart` plugs in
/// [MockSapsCases] today. The backend owner writes a real subclass and swaps
/// it in there. See docs/SAPS_BACKEND_CONTRACT.md.
abstract class SapsCaseService {
  /// Set once at start-up in main_saps.dart.
  static late SapsCaseService instance;

  /// All cases the officer may see. Replace the whole list on every change.
  final ValueNotifier<List<SapsCase>> cases = ValueNotifier(const []);

  /// True while the live connection is up (header shows "Live").
  final ValueNotifier<bool> connected = ValueNotifier(false);

  final ValueNotifier<DateTime?> lastUpdated = ValueNotifier(null);

  /// Message to show if loading failed, else null.
  final ValueNotifier<String?> loadError = ValueNotifier(null);

  final StreamController<SapsCase> _newSos =
      StreamController<SapsCase>.broadcast();

  /// Emits ONCE for each SOS that arrives after the first load.
  /// It makes the banner, row flash and sound happen.
  Stream<SapsCase> get newSosAlerts => _newSos.stream;

  /// Call from a subclass when a brand-new active SOS appears.
  @protected
  void announceNewSos(SapsCase c) => _newSos.add(c);

  Future<void> start();
  Future<void> stop();
  Future<void> refresh();

  /// Move a case to [status] and record who did it and why.
  Future<void> setStatus(SapsCase c, String status, {String? reason});

  /// Record that the officer opened a case (once per case is enough).
  Future<void> logOpened(SapsCase c);

  Future<List<AuditEntry>> audit(SapsCase c);
}
