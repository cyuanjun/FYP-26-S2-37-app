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
  }) = _ConnectedDevice;

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) =>
      _$ConnectedDeviceFromJson(json);

  bool get isPhoneSensors => deviceType == DeviceType.phoneSensors;

  /// Wearables can stream heart rate; the phone alone cannot.
}
