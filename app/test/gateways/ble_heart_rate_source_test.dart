import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/ble_heart_rate_source.dart';

// (#) Tests the BLE heart-rate gateway: parsing the GATT 0x2A37 packet and deriving avg/max samples.
void main() {
  // (#) Group covering the GATT Heart Rate Measurement byte parsing.
  group('GATT Heart Rate Measurement parsing (0x2A37)', () {
    // (#) (+) Check if a uint8-format packet (flag bit0 = 0) parses the HR value.
    test('uint8 format (flags bit0 = 0)', () {
      expect(BleHeartRateSource.parseHeartRate([0x00, 72]), 72);
      // Extra fields (energy expended, RR intervals) after the value are fine.
      expect(BleHeartRateSource.parseHeartRate([0x10, 145, 0x12, 0x03]), 145);
    });

    // (#) (+) Check if a uint16 little-endian packet (flag bit0 = 1) parses the HR value.
    test('uint16 little-endian format (flags bit0 = 1)', () {
      expect(BleHeartRateSource.parseHeartRate([0x01, 0x2C, 0x01]), 300);
      expect(BleHeartRateSource.parseHeartRate([0x01, 90, 0x00]), 90);
    });

    // (#) (-) Check if empty or too-short packets return null.
    test('malformed packets return null (negative)', () {
      expect(BleHeartRateSource.parseHeartRate([]), isNull);
      expect(BleHeartRateSource.parseHeartRate([0x00]), isNull); // no value
      expect(
          BleHeartRateSource.parseHeartRate([0x01, 90]), isNull); // short u16
    });

    // (#) (+) Check if avg and max are derived from the collected samples.
    test('avg/max derive from collected samples like the simulated source',
        () {
      final source = BleHeartRateSource('00:00:00:00:00:00');
      source.samples.addAll([120, 140, 160]);
      expect(source.avgHeartRate, 140);
      expect(source.maxHeartRate, 160);
    });
  });
}
