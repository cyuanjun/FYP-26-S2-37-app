import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/connected_device.dart';
import '../../entities/enums.dart';

/// BOUNDARY (gateway) — `connected_devices` CRUD (#7.1). Controls call this;
/// the UI never queries Supabase directly.
class DeviceGateway {
  DeviceGateway(this._client);

  final SupabaseClient _client;

  Future<List<ConnectedDevice>> listDevices(String userId) async {
    final rows = await _client
        .from('connected_devices')
        .select()
        .eq('user_id', userId)
        .order('device_type', ascending: true);
    return rows.map(ConnectedDevice.fromJson).toList();
  }

  /// The system-managed virtual device — present for every user, never removed.
  Future<ConnectedDevice> ensurePhoneSensors(String userId) async {
    final existing = await _client
        .from('connected_devices')
        .select()
        .eq('user_id', userId)
        .eq('device_type', 'phone_sensors')
        .maybeSingle();
    if (existing != null) return ConnectedDevice.fromJson(existing);
    final row = await _client.from('connected_devices').insert({
      'user_id': userId,
      'device_type': 'phone_sensors',
      'device_name': 'Phone sensors',
      'is_active': true,
    }).select().single();
    return ConnectedDevice.fromJson(row);
  }

  Future<ConnectedDevice> addDevice({
    required String userId,
    required DeviceType type,
    required String name,
  }) async {
    final row = await _client.from('connected_devices').insert({
      'user_id': userId,
      'device_type': _toDb(type),
      'device_name': name.trim(),
      'is_active': true,
      'last_synced_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();
    return ConnectedDevice.fromJson(row);
  }

  Future<void> setActive(String deviceId, bool active) async {
    await _client.from('connected_devices').update({'is_active': active}).eq('id', deviceId);
  }

  Future<void> removeDevice(String deviceId) async {
    await _client.from('connected_devices').delete().eq('id', deviceId);
  }

  Future<void> touchLastSynced(String deviceId) async {
    await _client
        .from('connected_devices')
        .update({'last_synced_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', deviceId);
  }

  String _toDb(DeviceType t) => switch (t) {
        DeviceType.appleWatch => 'apple_watch',
        DeviceType.phoneSensors => 'phone_sensors',
        _ => t.name,
      };
}

final deviceGatewayProvider =
    Provider<DeviceGateway>((ref) => DeviceGateway(Supabase.instance.client));
