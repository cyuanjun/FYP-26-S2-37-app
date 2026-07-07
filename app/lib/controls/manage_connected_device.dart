import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/device_gateway.dart';
import '../core/seq_log.dart';
import '../entities/connected_device.dart';
import '../entities/enums.dart';
import 'authenticate.dart';
import '../core/strings.dart';

/// The user's devices, with the phone-sensors virtual device guaranteed to
/// exist (system-managed, pinned first, never removable — #7.1 spec).
final connectedDevicesProvider = FutureProvider<List<ConnectedDevice>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const <ConnectedDevice>[];
  final gw = ref.watch(deviceGatewayProvider);
  await gw.ensurePhoneSensors(userId);
  final devices = await gw.listDevices(userId);
  devices.sort((a, b) {
    if (a.isPhoneSensors != b.isPhoneSensors) return a.isPhoneSensors ? -1 : 1;
    return a.deviceName.compareTo(b.deviceName);
  });
  return devices;
});

/// The wearable whose data feeds the next capture: first active non-phone
/// device (null = phone only).
final activeWearableProvider = FutureProvider<ConnectedDevice?>((ref) async {
  final devices = await ref.watch(connectedDevicesProvider.future);
  for (final d in devices) {
    if (!d.isPhoneSensors && d.isActive) return d;
  }
  return null;
});

/// The phone-sensors virtual device row (sessions captured without a wearable
/// link to it; null connectedDeviceId is reserved for manual entries).
final phoneSensorsDeviceProvider = FutureProvider<ConnectedDevice?>((ref) async {
  final devices = await ref.watch(connectedDevicesProvider.future);
  for (final d in devices) {
    if (d.isPhoneSensors) return d;
  }
  return null;
});

/// CONTROL — ManageConnectedDevice (#7.1): pair / toggle / remove / sync.
class ManageConnectedDevice {
  ManageConnectedDevice(this._ref);

  final Ref _ref;

  Future<ConnectedDevice?> pair(
      {required DeviceType type, required String name, String? bleRemoteId}) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null || name.isBlank) return null;
    SeqLog.msg('manage-device', 'ConnectedDevicesScreen', 'ManageConnectedDevice',
        'pair(${type.name}, $name${bleRemoteId != null ? ', ble' : ''})');
    final device = await _ref.read(deviceGatewayProvider).addDevice(
        userId: userId, type: type, name: name, bleRemoteId: bleRemoteId);
    _ref.invalidate(connectedDevicesProvider);
    return device;
  }

  Future<void> setActive(ConnectedDevice device, bool active) async {
    SeqLog.msg('manage-device', 'ConnectedDevicesScreen', 'ManageConnectedDevice',
        'setActive(${device.deviceName}, $active)');
    await _ref.read(deviceGatewayProvider).setActive(device.id, active);
    _ref.invalidate(connectedDevicesProvider);
  }

  /// Phone sensors are system-managed and cannot be removed.
  Future<bool> remove(ConnectedDevice device) async {
    if (device.isPhoneSensors) return false;
    SeqLog.msg('manage-device', 'ConnectedDevicesScreen', 'ManageConnectedDevice',
        'remove(${device.deviceName})');
    await _ref.read(deviceGatewayProvider).removeDevice(device.id);
    _ref.invalidate(connectedDevicesProvider);
    return true;
  }

  Future<void> markSynced(String deviceId) async {
    await _ref.read(deviceGatewayProvider).touchLastSynced(deviceId);
    _ref.invalidate(connectedDevicesProvider);
  }
}

final manageConnectedDeviceProvider =
    Provider<ManageConnectedDevice>(ManageConnectedDevice.new);
