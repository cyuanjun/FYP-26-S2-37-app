import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/ble_heart_rate_source.dart';

void main() {
  group('GATT Heart Rate Measurement parsing (0x2A37)', () {
    test('uint8 format (flags bit0 = 0)', () {
      expect(BleHeartRateSource.parseHeartRate([0x00, 72]), 72);
      // Extra fields (energy expended, RR intervals) after the value are fine.
      expect(BleHeartRateSource.parseHeartRate([0x10, 145, 0x12, 0x03]), 145);
    });

    test('uint16 little-endian format (flags bit0 = 1)', () {
      expect(BleHeartRateSource.parseHeartRate([0x01, 0x2C, 0x01]), 300);
      expect(BleHeartRateSource.parseHeartRate([0x01, 90, 0x00]), 90);
    });

    test('malformed packets return null (negative)', () {
      expect(BleHeartRateSource.parseHeartRate([]), isNull);
      expect(BleHeartRateSource.parseHeartRate([0x00]), isNull); // no value
      expect(
          BleHeartRateSource.parseHeartRate([0x01, 90]), isNull); // short u16
    });

    test('avg/max derive from collected samples like the simulated source',
        () {
      final source = BleHeartRateSource('00:00:00:00:00:00');
      source.samples.addAll([120, 140, 160]);
      expect(source.avgHeartRate, 140);
      expect(source.maxHeartRate, 160);
    });
  });
}
