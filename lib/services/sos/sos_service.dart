import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/supabase_service.dart';

class SosAlert {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhone;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  const SosAlert({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhone,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });
}

class SosService {
  SosService._();
  static final SosService instance = SosService._();

  final _supabase = SupabaseService.client;
  RealtimeChannel? _channel;

  String? get _uid => _supabase.auth.currentUser?.id;

  /// How many accepted circle members will receive an SOS.
  Future<int> circleCount() async {
    final uid = _uid;
    if (uid == null) return 0;

    final rows = await _supabase
        .from('trusted_circle_requests')
        .select('id')
        .eq('status', 'accepted')
        .or('requester_id.eq.$uid,recipient_id.eq.$uid');

    return (rows as List).length;
  }

  /// Creates the alert. Circle members' apps receive it in real time.
  Future<String> sendSos(double lat, double lng) async {
    final uid = _uid;
    if (uid == null) throw Exception('You need to be logged in to send an SOS.');

    final row = await _supabase
        .from('sos_alerts')
        .insert({
          'sender_id': uid,
          'latitude': lat,
          'longitude': lng,
        })
        .select('id')
        .single();

    return row['id'].toString();
  }

  Future<void> resolve(String alertId) async {
    await _supabase.from('sos_alerts').update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', alertId);
  }

  /// Phone numbers from the user's emergency_contacts (spaces removed).
  Future<List<String>> emergencyNumbers() async {
    final uid = _uid;
    if (uid == null) return [];

    final rows = await _supabase
        .from('emergency_contacts')
        .select('phone_number')
        .eq('user_id', uid);

    return (rows as List)
        .map((r) => (r['phone_number'] ?? '').toString().replaceAll(' ', ''))
        .where((n) => n.isNotEmpty)
        .toList();
  }

  /// Active alerts from the last 30 minutes (catches ones sent while the app was closed).
  Future<List<SosAlert>> fetchActiveAlerts() async {
    final uid = _uid;
    if (uid == null) return [];

    final since = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 30))
        .toIso8601String();

    final rows = await _supabase
        .from('sos_alerts')
        .select()
        .eq('status', 'active')
        .gte('created_at', since)
        .neq('sender_id', uid);

    final alerts = <SosAlert>[];

    for (final row in (rows as List)) {
      alerts.add(await _toAlert(row));
    }

    return alerts;
  }

  Future<SosAlert> _toAlert(Map<String, dynamic> row) async {
    var name = 'A trusted contact';
    String? phone;

    try {
      final p = await _supabase
          .from('profiles')
          .select('full_name, phone_number')
          .eq('id', row['sender_id'])
          .maybeSingle();

      if (p != null) {
        final fullName = (p['full_name'] ?? '').toString().trim();
        if (fullName.isNotEmpty) name = fullName;
        phone = p['phone_number']?.toString();
      }
    } catch (e) {
      print("SOS PROFILE ERROR: $e");
    }

    return SosAlert(
      id: row['id'].toString(),
      senderId: row['sender_id'].toString(),
      senderName: name,
      senderPhone: phone,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'].toString()),
    );
  }

  /// Live updates: new alerts from the circle, and alerts being resolved.
  void listen({
    required void Function(SosAlert alert) onAlert,
    required void Function(String alertId) onResolved,
  }) {
    stop();

    final uid = _uid;
    if (uid == null) return;

    _channel = _supabase
        .channel('sos-alerts-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'sos_alerts',
          callback: (payload) async {
            final row = payload.newRecord;
            if (row['sender_id'] == uid) return;
            onAlert(await _toAlert(row));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'sos_alerts',
          callback: (payload) {
            final row = payload.newRecord;
            if (row['status'] == 'resolved') {
              onResolved(row['id'].toString());
            }
          },
        )
        .subscribe();
  }

  void stop() {
    final channel = _channel;
    if (channel != null) {
      _supabase.removeChannel(channel);
      _channel = null;
    }
  }
}