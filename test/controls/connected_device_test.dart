import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/device_gateway.dart';
import 'package:wise_workout/boundaries/gateways/workout_data_source.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
import 'package:wise_workout/controls/active_workout.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/manage_connected_device.dart';
import 'package:wise_workout/entities/connected_device.dart';
import 'package:wise_workout/entities/enums.dart';

import '../helpers/fakes.dart';

void main() {
  ProviderContainer deviceContainer(FakeDeviceGateway gw, {String? userId = 'u1'}) {
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      deviceGatewayProvider.overrideWithValue(gw),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('connectedDevicesProvider', () {
    test('seeds the phone-sensors virtual device once, pinned first (positive)', () async {
      final gw = FakeDeviceGateway();
      final c = deviceContainer(gw);
      final devices = await c.read(connectedDevicesProvider.future);
      expect(devices.single.deviceType, DeviceType.phoneSensors);
      // Re-read: still exactly one phone device.
      c.invalidate(connectedDevicesProvider);
      final again = await c.read(connectedDevicesProvider.future);
      expect(again.where((d) => d.isPhoneSensors), hasLength(1));
    });

    test('signed out → empty, nothing seeded (negative)', () async {
      final gw = FakeDeviceGateway();
      final c = deviceContainer(gw, userId: null);
      expect(await c.read(connectedDevicesProvider.future), isEmpty);
      expect(gw.ensureCalls, 0);
    });
  });

  group('ManageConnectedDevice', () {
    test('pair adds a wearable; activeWearableProvider finds it (positive)', () async {
      final gw = FakeDeviceGateway();
      final c = deviceContainer(gw);
      final d = await c
          .read(manageConnectedDeviceProvider)
          .pair(type: DeviceType.appleWatch, name: 'Apple Watch Series 9');
      expect(d?.deviceType, DeviceType.appleWatch);
      final wearable = await c.read(activeWearableProvider.future);
      expect(wearable?.deviceName, 'Apple Watch Series 9');
    });

    test('pair rejects empty names (negative)', () async {
      final gw = FakeDeviceGateway();
      final c = deviceContainer(gw);
      final d = await c
          .read(manageConnectedDeviceProvider)
          .pair(type: DeviceType.fitbit, name: '   ');
      expect(d, isNull);
    });

    test('inactive wearable is not selected as the capture source', () async {
      final gw = FakeDeviceGateway();
      final c = deviceContainer(gw);
      final d = await c
          .read(manageConnectedDeviceProvider)
          .pair(type: DeviceType.garmin, name: 'Garmin');
      await c.read(manageConnectedDeviceProvider).setActive(d!, false);
      expect(await c.read(activeWearableProvider.future), isNull);
    });

    test('phone sensors cannot be removed (negative)', () async {
      final gw = FakeDeviceGateway();
      final c = deviceContainer(gw);
      final devices = await c.read(connectedDevicesProvider.future);
      final ok = await c.read(manageConnectedDeviceProvider).remove(devices.single);
      expect(ok, isFalse);
      expect(gw.devices, hasLength(1));
    });
  });

  group('WearableHrSource (simulated BLE)', () {
    test('hr curve: rest at start, working zone after ramp', () {
      expect(WearableHrSource.hrAt(0), 70);
      final atPeak = WearableHrSource.hrAt(300);
      expect(atPeak, inInclusiveRange(120, 140)); // ~130 ± wave
    });

    test('avg/max derive from recorded samples', () {
      final src = WearableHrSource();
      for (var t = 0; t < 60; t++) {
        src.recordTick(t);
      }
      expect(src.samples, hasLength(60));
      expect(src.maxHeartRate, greaterThanOrEqualTo(src.avgHeartRate!));
      expect(src.avgHeartRate, inInclusiveRange(60, 120));
    });

    test('no samples → null stats (negative)', () {
      final src = WearableHrSource();
      expect(src.avgHeartRate, isNull);
      expect(src.maxHeartRate, isNull);
    });
  });

  group('ActiveWorkout with a paired wearable', () {
    test('session links to wearable, HR lands in end metrics, sync stamped', () async {
      final gw = FakeWorkoutGateway(
          endResult: {'xp_gained': 20, 'leveled_up': false, 'current_streak': 1});
      final src = FakeWorkoutDataSource();
      final deviceGw = FakeDeviceGateway();
      deviceGw.devices.add(const ConnectedDevice(
          id: 'dev-watch',
          userId: 'u1',
          deviceType: DeviceType.appleWatch,
          deviceName: 'Apple Watch'));
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        workoutGatewayProvider.overrideWithValue(gw),
        deviceGatewayProvider.overrideWithValue(deviceGw),
        workoutDataSourceFactoryProvider.overrideWithValue(() => src),
      ]);
      addTearDown(() {
        src.dispose();
        c.dispose();
      });

      await c.read(activeWorkoutProvider.notifier).start(runningType);
      expect(gw.startSessionCalls.single.connectedDeviceId, 'dev-watch');

      // Let the simulated HR stream tick a couple of times.
      await Future<void>.delayed(const Duration(milliseconds: 2300));
      final result = await c.read(activeWorkoutProvider.notifier).end();
      expect(result['xp_gained'], 20);
      final metrics = gw.endSessionCalls.single.metrics;
      expect(metrics['avg_heart_rate'], isNotNull);
      expect(metrics['max_heart_rate'],
          greaterThanOrEqualTo(metrics['avg_heart_rate'] as int));
      expect(deviceGw.syncedIds, ['dev-watch']);
    });

    test('no wearable → session links to phone sensors, no HR in metrics', () async {
      final gw = FakeWorkoutGateway(
          endResult: {'xp_gained': 20, 'leveled_up': false, 'current_streak': 1});
      final src = FakeWorkoutDataSource();
      final deviceGw = FakeDeviceGateway();
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        workoutGatewayProvider.overrideWithValue(gw),
        deviceGatewayProvider.overrideWithValue(deviceGw),
        workoutDataSourceFactoryProvider.overrideWithValue(() => src),
      ]);
      addTearDown(() {
        src.dispose();
        c.dispose();
      });

      await c.read(activeWorkoutProvider.notifier).start(runningType);
      expect(gw.startSessionCalls.single.connectedDeviceId, 'dev-phone-u1');
      await c.read(activeWorkoutProvider.notifier).end();
      final metrics = gw.endSessionCalls.single.metrics;
      expect(metrics.containsKey('avg_heart_rate'), isFalse);
      expect(deviceGw.syncedIds, isEmpty);
    });
  });
}
