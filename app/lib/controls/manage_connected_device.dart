import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/device_gateway.dart';
import '../core/seq_log.dart';
import '../entities/connected_device.dart';
import '../entities/enums.dart';
import 'authenticate.dart';
import '../core/strings.dart';

// (#) The user's paired devices. It makes sure the built-in phone-sensors device
// (#) exists, loads the rest, and sorts so phone sensors is pinned first, then
// (#) the others by name. That virtual device is system-managed and never removed.
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

// (#) The wearable that will feed the next recording: the first active non-phone
// (#) device, or null when it's phone sensors only.
final activeWearableProvider = FutureProvider<ConnectedDevice?>((ref) async {
  final devices = await ref.watch(connectedDevicesProvider.future);
  for (final d in devices) {
    if (!d.isPhoneSensors && d.isActive) return d;
  }
  return null;
});

// (#) The built-in phone-sensors device row. Sensor-only sessions link to it; a
// (#) null device id instead means a manual entry.
final phoneSensorsDeviceProvider = FutureProvider<ConnectedDevice?>((ref) async {
  final devices = await ref.watch(connectedDevicesProvider.future);
  for (final d in devices) {
    if (d.isPhoneSensors) return d;
  }
  return null;
});

// (#) Manages paired devices. It can pair a new one, toggle a device active,
// (#) remove one, and stamp last-synced, refreshing the list after each. Phone
// (#) sensors are system-managed and can't be removed.
class ManageConnectedDevice {
  ManageConnectedDevice(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway and user id

  // (#) Pairs a new device (optionally with a BLE id); returns it, or null if not
  // (#) signed in or the name is blank. Reloads the device list.
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

  // (#) Turns a device on or off as the active data source and reloads the list.
  Future<void> setActive(ConnectedDevice device, bool active) async {
    SeqLog.msg('manage-device', 'ConnectedDevicesScreen', 'ManageConnectedDevice',
        'setActive(${device.deviceName}, $active)');
    await _ref.read(deviceGatewayProvider).setActive(device.id, active);
    _ref.invalidate(connectedDevicesProvider);
  }

  // (#) Removes a device and reloads the list. Refuses (returns false) for the
  // (#) phone-sensors device since it's system-managed.
  Future<bool> remove(ConnectedDevice device) async {
    if (device.isPhoneSensors) return false;
    SeqLog.msg('manage-device', 'ConnectedDevicesScreen', 'ManageConnectedDevice',
        'remove(${device.deviceName})');
    await _ref.read(deviceGatewayProvider).removeDevice(device.id);
    _ref.invalidate(connectedDevicesProvider);
    return true;
  }

  // (#) Bumps a device's last-synced time (called after it feeds a workout).
  Future<void> markSynced(String deviceId) async {
    await _ref.read(deviceGatewayProvider).touchLastSynced(deviceId);
    _ref.invalidate(connectedDevicesProvider);
  }
}

// (#) Hands the devices screen the ManageConnectedDevice control.
final manageConnectedDeviceProvider =
    Provider<ManageConnectedDevice>(ManageConnectedDevice.new);
