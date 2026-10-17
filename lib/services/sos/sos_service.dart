import 'package:flutter/foundation.dart';

/// One alert that has been sent and not yet cancelled.
class ActiveSosAlert {
  ActiveSosAlert({
    required this.id,
    required this.trigger,
    required this.sentAt,
  });

  final String id;
  final String trigger; // 'button' or 'shake'
  final DateTime sentAt;
}

/// The single place an SOS alert is sent from. The button and the shake
/// trigger both call sendAlert, so the backend is connected only once.
class SosService {
  SosService._();
  static final SosService instance = SosService._();

  ActiveSosAlert? _active;

  ActiveSosAlert? get activeAlert => _active;
  bool get hasActiveAlert => _active != null;

  /// Sends an alert straight away. If one is already active it returns
  /// that one instead, so a second trigger can never send a duplicate.
  Future<ActiveSosAlert> sendAlert({required String trigger}) async {
    final existing = _active;
    if (existing != null) return existing;

    final alert = ActiveSosAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trigger: trigger,
      sentAt: DateTime.now(),
    );
    // Set before any await, so two triggers at once can't both send.
    _active = alert;

    // TODO(alerts-owner): get the GPS location and insert the alert into
    // Supabase here. If the insert fails, set _active = null again so
    // the user can retry.
    debugPrint('SOS sent via $trigger at ${alert.sentAt}');
    return alert;
  }

  /// Marks the active alert as cancelled by the user.
  Future<void> cancelAlert({required String reason}) async {
    final alert = _active;
    if (alert == null) return;
    _active = null;

    // TODO(alerts-owner): update the alert's status in Supabase, so
    // responders see it was cancelled. Don't lower the user's
    // trust_score for a quick cancel.
    debugPrint('SOS ${alert.id} cancelled: $reason');
  }
}