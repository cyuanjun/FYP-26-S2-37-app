import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'workout_data_source.dart';

// (#) Talks to a real Bluetooth heart-rate strap over the standard GATT service.
// (#) The workout controls use it to stream live bpm off a paired device while a
// (#) session runs. Needs real hardware, so the mock source stays the demo default.
class BleHeartRateSource implements HrSource {
  // (#) Builds the source for one paired device, given its Bluetooth id.
  BleHeartRateSource(this.remoteId);

  final String remoteId; // (#) the device's Bluetooth id saved when it was paired

  static final heartRateService = Guid('180D'); // (#) standard GATT heart-rate service id
  static final hrMeasurementChar = Guid('2A37'); // (#) the bpm reading inside that service

  final _controller = StreamController<LiveMetrics>.broadcast(); // (#) pushes each bpm reading out
  final samples = <int>[]; // (#) every bpm seen this session, for avg and max
  BluetoothDevice? _device; // (#) the connected strap, once start() finds it
  StreamSubscription<List<int>>? _hrSub; // (#) listener on the device's bpm notifications

  // (#) The live metrics stream the workout control listens to.
  @override
  Stream<LiveMetrics> get metrics => _controller.stream;

  // (#) No GPS track from a heart-rate strap, so this is always empty.
  @override
  List<Map<String, dynamic>> get trackPoints => const [];

  // (#) Average bpm over the whole session, or null if nothing was read.
  @override
  int? get avgHeartRate => samples.isEmpty
      ? null
      : (samples.reduce((a, b) => a + b) / samples.length).round();

  // (#) Highest bpm seen this session, or null if nothing was read.
  @override
  int? get maxHeartRate =>
      samples.isEmpty ? null : samples.reduce((a, b) => a > b ? a : b);

  // (#) Decodes one raw GATT bpm packet. The first flag bit says whether the
  // (#) value is one byte or two. Returns null for a broken packet. Unit tested.
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

  // (#) Connects to the strap, finds the heart-rate service, and starts
  // (#) collecting each bpm reading as it arrives.
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

  // (#) Stops listening, disconnects the strap, and closes the stream.
  @override
  Future<void> stop() async {
    await _hrSub?.cancel();
    try {
      await _device?.disconnect();
    } catch (_) {}
    await _controller.close();
  }
}

// (#) A nearby heart-rate device that a live scan turned up, shown in the pairing sheet.
class ScannedBleDevice {
  // (#) Holds one found device's Bluetooth id and display name.
  const ScannedBleDevice({required this.remoteId, required this.name});

  final String remoteId; // (#) the device's Bluetooth id
  final String name; // (#) the name to show in the list
}

// (#) Scans a few seconds for nearby heart-rate straps. Returns an empty list
// (#) when Bluetooth is off or unavailable, so the sheet falls back to demo devices.
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
