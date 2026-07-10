import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/connected_device.dart';
import '../../entities/enums.dart';

// (#) Handles the connected_devices table in Supabase. Controls use it to list a
// (#) user's paired devices, add or remove one, and keep the last-synced time fresh.
class DeviceGateway {
  // (#) Keeps the Supabase client used for all device rows.
  DeviceGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client for table calls

  // (#) Loads all of a user's paired devices, ordered by type.
  Future<List<ConnectedDevice>> listDevices(String userId) async {
    final rows = await _client
        .from('connected_devices')
        .select()
        .eq('user_id', userId)
        .order('device_type', ascending: true);
    return rows.map(ConnectedDevice.fromJson).toList();
  }

  // (#) Makes sure the built-in phone-sensors device exists for a user, adding
  // (#) it if missing. It is virtual and never gets removed.
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

  // (#) Adds a newly paired device row and stamps it as just synced.
  Future<ConnectedDevice> addDevice({
    required String userId,
    required DeviceType type,
    required String name,
    String? bleRemoteId,
  }) async {
    final row = await _client.from('connected_devices').insert({
      'user_id': userId,
      'device_type': _toDb(type),
      'device_name': name.trim(),
      'is_active': true,
      'last_synced_at': DateTime.now().toUtc().toIso8601String(),
      'ble_remote_id': ?bleRemoteId,
    }).select().single();
    return ConnectedDevice.fromJson(row);
  }

  // (#) Turns a device on or off without deleting it.
  Future<void> setActive(String deviceId, bool active) async {
    await _client.from('connected_devices').update({'is_active': active}).eq('id', deviceId);
  }

  // (#) Deletes a device row for good.
  Future<void> removeDevice(String deviceId) async {
    await _client.from('connected_devices').delete().eq('id', deviceId);
  }

  // (#) Bumps a device's last-synced time to now.
  Future<void> touchLastSynced(String deviceId) async {
    await _client
        .from('connected_devices')
        .update({'last_synced_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', deviceId);
  }

  // (#) Turns a device-type enum into the snake_case string the column expects.
  String _toDb(DeviceType t) => switch (t) {
        DeviceType.appleWatch => 'apple_watch',
        DeviceType.phoneSensors => 'phone_sensors',
        _ => t.name,
      };
}

// (#) Riverpod provider handing out the device gateway on the live client.
final deviceGatewayProvider =
    Provider<DeviceGateway>((ref) => DeviceGateway(Supabase.instance.client));
