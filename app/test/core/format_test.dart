import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/core/format.dart';

void main() {
  group('fmtDuration', () {
    test('mm:ss under an hour', () {
      expect(fmtDuration(const Duration(seconds: 28)), '00:28');
      expect(fmtDuration(const Duration(minutes: 5, seconds: 9)), '05:09');
    });
    test('h:mm:ss over an hour', () {
      expect(fmtDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    });
  });

  group('fmtKm', () {
    test('metres to 2dp km', () {
      expect(fmtKm(5000), '5.00');
      expect(fmtKm(0), '0.00');
      expect(fmtKm(1234), '1.23');
    });
  });

  group('fmtPace', () {
    test('returns placeholder for ~zero distance (negative path)', () {
      expect(fmtPace(0, const Duration(minutes: 10)), '--:--');
      expect(fmtPace(1000, Duration.zero), '--:--');
    });
    test('computes mm:ss per km', () {
      // 5 km in 30 min => 6:00 /km
      expect(fmtPace(5000, const Duration(minutes: 30)), '6:00');
    });
  });

  group('iconForSlug', () {
    test('known slugs', () {
      expect(iconForSlug('running'), '🏃');
      expect(iconForSlug('yoga'), '🧘');
    });
    test('unknown slug falls back (negative)', () {
      expect(iconForSlug('surfing'), '🏋️');
    });
  });

  group('relativeDay', () {
    final now = DateTime(2026, 6, 10); // Wednesday
    test('today / yesterday', () {
      expect(relativeDay(DateTime(2026, 6, 10, 8), now: now), 'Today');
      expect(relativeDay(DateTime(2026, 6, 9, 8), now: now), 'Yesterday');
    });
    test('older shows weekday d mon', () {
      expect(relativeDay(DateTime(2026, 6, 3), now: now), 'Wed 3 Jun');
    });
    test('UTC timestamps compare by LOCAL date (regression: 01:40 SGT bug)', () {
      // A DB timestamp early "today" local, expressed in UTC — before the fix
      // the raw UTC components made this read as the previous day.
      final localNow = DateTime(2026, 7, 6, 1, 40);
      final utcStamp = DateTime(2026, 7, 6, 0, 30).toUtc();
      expect(relativeDay(utcStamp, now: localNow), 'Today');
    });
  });

  group('startOfWeek', () {
    test('returns Monday 00:00', () {
      final mon = startOfWeek(DateTime(2026, 6, 10, 15)); // Wed
      expect(mon, DateTime(2026, 6, 8));
      expect(mon.weekday, DateTime.monday);
    });
  });
}
