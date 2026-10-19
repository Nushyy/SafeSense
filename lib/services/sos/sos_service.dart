import 'package:flutter/foundation.dart';

/// Represents an SOS demonstration alert.
///
/// This alert is stored locally in memory.
/// It is not sent to Supabase or emergency responders.
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

/// Central service for managing SOS demonstration alerts.
///
/// Both the SOS button and shake detector use this service.
///
/// IMPORTANT:
/// This is currently a prototype.
/// No real emergency notifications are sent.
class SosService {
  SosService._();

  static final SosService instance = SosService._();

  ActiveSosAlert? _active;

  /// Returns the currently active demonstration alert.
  ActiveSosAlert? get activeAlert => _active;

  /// Checks whether a demonstration alert is active.
  bool get hasActiveAlert => _active != null;

  /// Activates an SOS demonstration.
  ///
  /// If an alert already exists, it returns the existing alert
  /// to prevent duplicate activations.
  Future<ActiveSosAlert> sendAlert({required String trigger}) async {
    final existing = _active;

    if (existing != null) {
      return existing;
    }

    final alert = ActiveSosAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trigger: trigger,
      sentAt: DateTime.now(),
    );

    // Store the alert before any asynchronous operations
    // to prevent simultaneous duplicate activations.
    _active = alert;

    // TODO:
    // 1. Obtain the user's GPS location.
    // 2. Insert the SOS alert into Supabase.
    // 3. Notify authorized community responders.
    // 4. Handle failures and allow retries.
    //
    // These operations are NOT implemented yet.

    debugPrint('SOS DEMO activated via $trigger at ${alert.sentAt}');

    return alert;
  }

  /// Cancels the currently active SOS demonstration.
  ///
  /// This clears the local alert so another demonstration
  /// can be activated.
  Future<void> cancelAlert({required String reason}) async {
    final alert = _active;

    if (alert == null) {
      return;
    }

    // TODO:
    // When Supabase integration is implemented,
    // update the alert's status in the database.
    //
    // No backend cancellation occurs at present.

    debugPrint('SOS DEMO ${alert.id} cancelled: $reason');

    // Clear the local active alert.
    _active = null;
  }
}
