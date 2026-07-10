import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/core/format.dart';

// (#) Tests the core formatting helpers: duration, km, pace, slug icons, relative day, start of week.
void main() {
  // (#) Group covering duration formatting.
  group('fmtDuration', () {
    // (#) (+) Check if durations under an hour render as mm:ss.
    test('mm:ss under an hour', () {
      expect(fmtDuration(const Duration(seconds: 28)), '00:28');
      expect(fmtDuration(const Duration(minutes: 5, seconds: 9)), '05:09');
    });
    // (#) (+) Check if durations over an hour render as h:mm:ss.
    test('h:mm:ss over an hour', () {
      expect(fmtDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    });
  });

  // (#) Group covering metres-to-km formatting.
  group('fmtKm', () {
    // (#) (+) Check if metres convert to km at 2 decimal places.
    test('metres to 2dp km', () {
      expect(fmtKm(5000), '5.00');
      expect(fmtKm(0), '0.00');
      expect(fmtKm(1234), '1.23');
    });
  });

  // (#) Group covering pace formatting.
  group('fmtPace', () {
    // (#) (-) Check if near-zero distance or zero time returns the --:-- placeholder.
    test('returns placeholder for ~zero distance (negative path)', () {
      expect(fmtPace(0, const Duration(minutes: 10)), '--:--');
      expect(fmtPace(1000, Duration.zero), '--:--');
    });
    // (#) (+) Check if pace computes to mm:ss per km.
    test('computes mm:ss per km', () {
      // 5 km in 30 min => 6:00 /km
      expect(fmtPace(5000, const Duration(minutes: 30)), '6:00');
    });
  });

  // (#) Group covering the workout-slug to emoji mapping.
  group('iconForSlug', () {
    // (#) (+) Check if known slugs map to their emoji.
    test('known slugs', () {
      expect(iconForSlug('running'), '🏃');
      expect(iconForSlug('yoga'), '🧘');
    });
    // (#) (-) Check if an unknown slug falls back to the default icon.
    test('unknown slug falls back (negative)', () {
      expect(iconForSlug('surfing'), '🏋️');
    });
  });

  // (#) Group covering the relative-day label.
  group('relativeDay', () {
    final now = DateTime(2026, 6, 10); // Wednesday
    // (#) (+) Check if same-day and prior-day render as Today and Yesterday.
    test('today / yesterday', () {
      expect(relativeDay(DateTime(2026, 6, 10, 8), now: now), 'Today');
      expect(relativeDay(DateTime(2026, 6, 9, 8), now: now), 'Yesterday');
    });
    // (#) (+) Check if older dates render as weekday d mon.
    test('older shows weekday d mon', () {
      expect(relativeDay(DateTime(2026, 6, 3), now: now), 'Wed 3 Jun');
    });
    // (#) (+) Check if a UTC timestamp is compared by local date, not raw UTC (regression guard).
    test('UTC timestamps compare by LOCAL date (regression: 01:40 SGT bug)', () {
      // A DB timestamp early "today" local, expressed in UTC — before the fix
      // the raw UTC components made this read as the previous day.
      final localNow = DateTime(2026, 7, 6, 1, 40);
      final utcStamp = DateTime(2026, 7, 6, 0, 30).toUtc();
      expect(relativeDay(utcStamp, now: localNow), 'Today');
    });
  });

  // (#) Group covering the start-of-week helper.
  group('startOfWeek', () {
    // (#) (+) Check if startOfWeek returns the Monday at 00:00 for a mid-week date.
    test('returns Monday 00:00', () {
      final mon = startOfWeek(DateTime(2026, 6, 10, 15)); // Wed
      expect(mon, DateTime(2026, 6, 8));
      expect(mon.weekday, DateTime.monday);
    });
  });
}
