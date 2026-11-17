
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../location/location_service.dart';

class ActiveSosAlert {
  ActiveSosAlert({
    required this.id,
    required this.trigger,
    required this.sentAt,
    this.latitude,
    this.longitude,
    this.senderId,
    this.senderName,
    this.senderPhone,
  });

  final String id;
  final String trigger;
  final DateTime sentAt;
  final double? latitude;
  final double? longitude;
  final String? senderId;
  final String? senderName;
  final String? senderPhone;
}

class SosService {
  SosService._();

  static final SosService instance = SosService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  ActiveSosAlert? _active;
  Future<ActiveSosAlert>? _pendingSend;
  RealtimeChannel? _channel;

  ActiveSosAlert? get activeAlert => _active;

  bool get hasActiveAlert => _active != null;

  Future<ActiveSosAlert> sendAlert({required String trigger}) {
    if (_active != null) {
      return Future.value(_active!);
    }

    if (_pendingSend != null) {
      return _pendingSend!;
    }

    final future = _createAlert(trigger);
    _pendingSend = future;

    return future.whenComplete(() {
      _pendingSend = null;
    });
  }

  Future<ActiveSosAlert> _createAlert(String trigger) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to activate SOS.');
    }

    final existing = await _supabase
        .from('sos_alerts')
        .select('id, created_at, latitude, longitude')
        .eq('sender_id', user.id)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      final alert = ActiveSosAlert(
        id: existing['id'].toString(),
        trigger: trigger,
        sentAt: DateTime.parse(existing['created_at'].toString()),
        latitude: (existing['latitude'] as num?)?.toDouble(),
        longitude: (existing['longitude'] as num?)?.toDouble(),
        senderId: user.id,
      );

      _active = alert;
      return alert;
    }

    final position = await LocationService().getCurrentLocation();

    if (position == null) {
      throw Exception(
        'Unable to obtain GPS location. '
        'Please enable location services and try again.',
      );
    }

    final response = await _supabase
        .from('sos_alerts')
        .insert({
          'sender_id': user.id,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'status': 'active',
        })
        .select('id, created_at, latitude, longitude')
        .single();

    final alert = ActiveSosAlert(
      id: response['id'].toString(),
      trigger: trigger,
      sentAt: DateTime.parse(response['created_at'].toString()),
      latitude: (response['latitude'] as num?)?.toDouble(),
      longitude: (response['longitude'] as num?)?.toDouble(),
      senderId: user.id,
    );

    _active = alert;

    debugPrint('SOS alert saved to Supabase: ${alert.id}');

    return alert;
  }

  Future<void> cancelAlert({required String reason}) async {
    final alert = _active;

    if (alert == null) return;

    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to resolve SOS.');
    }

    await _supabase
        .from('sos_alerts')
        .update({
          'status': 'resolved',
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', alert.id)
        .eq('sender_id', user.id)
        .eq('status', 'active')
        .select('id')
        .single();

    debugPrint('SOS alert resolved: ${alert.id}. Reason: $reason');

    _active = null;
  }

  Future<Set<String>> _trustedMemberIds() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return {};

    final rows = await _supabase
        .from('trusted_circle_requests')
        .select('requester_id, recipient_id')
        .eq('status', 'accepted')
        .or(
          'requester_id.eq.${user.id},recipient_id.eq.${user.id}',
        );

    final ids = <String>{};

    for (final row in rows) {
      final requester = row['requester_id']?.toString();
      final recipient = row['recipient_id']?.toString();

      if (requester == user.id && recipient != null) {
        ids.add(recipient);
      } else if (recipient == user.id && requester != null) {
        ids.add(requester);
      }
    }

    return ids;
  }

  Future<ActiveSosAlert> _parseAlert(
    Map<String, dynamic> row,
  ) async {
    final senderId = row['sender_id'].toString();
    var senderName = 'Trusted Circle member';
    String? senderPhone;

    try {
      final profile = await _supabase
          .from('profiles')
          .select('full_name, phone_number')
          .eq('id', senderId)
          .maybeSingle();

      if (profile != null) {
        final name =
            (profile['full_name'] ?? '').toString().trim();

        if (name.isNotEmpty) {
          senderName = name;
        }

        senderPhone = profile['phone_number']?.toString();
      }
    } catch (e) {
      debugPrint('SOS profile lookup error: $e');
    }

    return ActiveSosAlert(
      id: row['id'].toString(),
      trigger: 'trusted_circle',
      sentAt: DateTime.parse(row['created_at'].toString()),
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      senderId: senderId,
      senderName: senderName,
      senderPhone: senderPhone,
    );
  }

  Future<List<ActiveSosAlert>> fetchActiveAlerts() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return [];

    final trustedIds = await _trustedMemberIds();

    if (trustedIds.isEmpty) return [];

    final since = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 30))
        .toIso8601String();

    final rows = await _supabase
        .from('sos_alerts')
        .select()
        .eq('status', 'active')
        .gte('created_at', since)
        .inFilter('sender_id', trustedIds.toList());

    final alerts = <ActiveSosAlert>[];

    for (final row in rows) {
      alerts.add(await _parseAlert(row));
    }

    return alerts;
  }

  Future<void> listen({
    required void Function(ActiveSosAlert alert) onAlert,
    required void Function(String id) onResolved,
  }) async {
    stop();

    final user = _supabase.auth.currentUser;

    if (user == null) return;

    final trustedIds = await _trustedMemberIds();

    if (trustedIds.isEmpty) return;

    _channel = _supabase
        .channel('trusted-circle-sos-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'sos_alerts',
          callback: (payload) async {
            final row = payload.newRecord;
            final senderId = row['sender_id']?.toString();

            if (senderId == null ||
                !trustedIds.contains(senderId)) {
              return;
            }

            try {
              final alert = await _parseAlert(row);
              onAlert(alert);
            } catch (e) {
              debugPrint('SOS Realtime insert error: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'sos_alerts',
          callback: (payload) {
            final row = payload.newRecord;
            final senderId = row['sender_id']?.toString();

            if (senderId == null ||
                !trustedIds.contains(senderId)) {
              return;
            }

            if (row['status'] == 'resolved') {
              onResolved(row['id'].toString());
            }
          },
        )
        .subscribe();

    debugPrint('Trusted Circle SOS Realtime listener started');
  }

  void stop() {
    final channel = _channel;

    if (channel != null) {
      _supabase.removeChannel(channel);
      _channel = null;
    }
  }
}
