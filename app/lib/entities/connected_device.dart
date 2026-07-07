import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'connected_device.freezed.dart';
part 'connected_device.g.dart';

/// ENTITY — a paired data source (#7.1). `phone_sensors` is the system-managed
/// virtual device: always present, can't be removed. Sessions reference their
/// source via WorkoutSession.connectedDeviceId (null = manual entry).
@freezed
abstract class ConnectedDevice with _$ConnectedDevice {
  const ConnectedDevice._();

  const factory ConnectedDevice({
    required String id,
    required String userId,
    required DeviceType deviceType,
    required String deviceName,
    DateTime? lastSyncedAt,
    @Default(true) bool isActive,

    /// Bluetooth remote id captured by a real BLE scan; null = mock pairing
    /// (the simulated HR stream).
    String? bleRemoteId,
  }) = _ConnectedDevice;

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) =>
      _$ConnectedDeviceFromJson(json);

  bool get isPhoneSensors => deviceType == DeviceType.phoneSensors;

  /// True when this pairing came from a real Bluetooth scan — sessions then
  /// stream HR via BleHeartRateSource instead of the simulated wearable.
  bool get isRealBle => bleRemoteId != null && bleRemoteId!.isNotEmpty;
}
