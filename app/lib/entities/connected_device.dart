import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'connected_device.freezed.dart';
part 'connected_device.g.dart';

// (#) A data source the user has paired for tracking. Might be the phone's own
// (#) sensors or a real Bluetooth heart-rate strap. Knows its type, name and
// (#) whether it came from a live BLE scan. The phone-sensors one is always
// (#) present and can't be removed.
@freezed
abstract class ConnectedDevice with _$ConnectedDevice {
  const ConnectedDevice._();

  const factory ConnectedDevice({
    required String id,
    required String userId,
    required DeviceType deviceType, // (#) phone sensors, watch, strap, etc.
    required String deviceName,
    DateTime? lastSyncedAt, // (#) when it last sent data over
    @Default(true) bool isActive,

    // (#) real Bluetooth id from a live scan, null means it's a mock pairing
    String? bleRemoteId,
  }) = _ConnectedDevice;

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) =>
      _$ConnectedDeviceFromJson(json);

  // (#) true for the built-in phone-sensors virtual device
  bool get isPhoneSensors => deviceType == DeviceType.phoneSensors;

  // (#) true when it's a real paired strap, so sessions stream live HR instead
  // (#) of the simulated wearable feed
  bool get isRealBle => bleRemoteId != null && bleRemoteId!.isNotEmpty;
}
