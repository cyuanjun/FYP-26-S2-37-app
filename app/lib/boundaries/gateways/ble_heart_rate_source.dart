import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'workout_data_source.dart';

/// BOUNDARY (gateway) — REAL Bluetooth heart-rate capture, the class-swap
/// counterpart of the simulated WearableHrSource (locked architecture: new
/// class, no refactor). Connects to a device paired via a real BLE scan
/// (ConnectedDevice.bleRemoteId) and subscribes to the standard GATT Heart
/// Rate service. Requires physical hardware — the iOS simulator has no
/// Bluetooth, which is why the mock pairing path stays the demo default.
class BleHeartRateSource implements HrSource {
  BleHeartRateSource(this.remoteId);

  /// The platform Bluetooth identifier stored at pairing time.
  final String remoteId;

  static final heartRateService = Guid('180D');
  static final hrMeasurementChar = Guid('2A37');

  final _controller = StreamController<LiveMetrics>.broadcast();
  final samples = <int>[];
  BluetoothDevice? _device;
  StreamSubscription<List<int>>? _hrSub;

  @override
  Stream<LiveMetrics> get metrics => _controller.stream;

  @override
  List<Map<String, dynamic>> get trackPoints => const [];

  @override
  int? get avgHeartRate => samples.isEmpty
      ? null
      : (samples.reduce((a, b) => a + b) / samples.length).round();

  @override
  int? get maxHeartRate =>
      samples.isEmpty ? null : samples.reduce((a, b) => a > b ? a : b);

  /// Parses a GATT Heart Rate Measurement (0x2A37) packet. Flags bit 0
  /// selects the value width: 0 → uint8 at byte 1, 1 → uint16 LE at bytes
  /// 1–2. Returns null for malformed packets. Pure — unit-tested.
  static int? parseHeartRate(List<int> data) {
    if (data.isEmpty) return null;
    final flags = data[0];
    final sixteenBit = flags & 0x01 == 0x01;
    if (sixteenBit) {
      if (data.length < 3) return null;
      return data[1] | (data[2] << 8);
    }
    if (data.length < 2) return null;
    return data[1];
  }

  @override
  Future<void> start() async {
    final device = BluetoothDevice.fromId(remoteId);
    _device = device;
    // Connection failures surface to ActiveWorkout, which falls back to the
    // simulated stream rather than losing the session.
    await device.connect(timeout: const Duration(seconds: 10));
    final services = await device.discoverServices();
    final hrService = services.firstWhere(
      (s) => s.uuid == heartRateService,
      orElse: () => throw StateError('Device has no Heart Rate service'),
    );
    final hrChar = hrService.characteristics.firstWhere(
      (c) => c.uuid == hrMeasurementChar,
      orElse: () =>
          throw StateError('Device has no HR Measurement characteristic'),
    );
    await hrChar.setNotifyValue(true);
    _hrSub = hrChar.onValueReceived.listen((data) {
      final hr = parseHeartRate(data);
      if (hr == null) return;
      samples.add(hr);
      if (!_controller.isClosed) _controller.add(LiveMetrics(heartRate: hr));
    });
  }

  @override
  Future<void> stop() async {
    await _hrSub?.cancel();
    try {
      await _device?.disconnect();
    } catch (_) {}
    await _controller.close();
  }
}

/// A device found by a real BLE scan (the pairing sheet's live section).
class ScannedBleDevice {
  const ScannedBleDevice({required this.remoteId, required this.name});

  final String remoteId;
  final String name;
}

/// Scans for nearby devices advertising the Heart Rate service. Returns []
/// wherever Bluetooth is unavailable (simulator, permission denied, adapter
/// off) so the pairing sheet can fall back to the demo device list.
Future<List<ScannedBleDevice>> scanForHeartRateDevices(
    {Duration timeout = const Duration(seconds: 4)}) async {
  try {
    if (await FlutterBluePlus.isSupported == false) return const [];
    final found = <String, ScannedBleDevice>{};
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.platformName;
        if (name.isEmpty) continue;
        found[r.device.remoteId.str] =
            ScannedBleDevice(remoteId: r.device.remoteId.str, name: name);
      }
    });
    await FlutterBluePlus.startScan(
        withServices: [BleHeartRateSource.heartRateService], timeout: timeout);
    await FlutterBluePlus.isScanning.where((s) => !s).first;
    await sub.cancel();
    return found.values.toList();
  } catch (_) {
    return const [];
  }
}
