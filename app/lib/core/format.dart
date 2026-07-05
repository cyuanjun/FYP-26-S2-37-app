// Small display formatters shared by the workout screens.

String fmtDuration(Duration d) {
  final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
  final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$mm:$ss' : '$mm:$ss';
}

String fmtKm(double meters) => (meters / 1000).toStringAsFixed(2);

/// Average pace as mm:ss per km over the elapsed time.
String fmtPace(double meters, Duration elapsed) {
  if (meters < 5 || elapsed.inSeconds == 0) return '--:--';
  final secPerKm = elapsed.inSeconds / (meters / 1000);
  final m = secPerKm ~/ 60;
  final s = (secPerKm % 60).round();
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Workout-type glyph by slug (History/Social cards).
String iconForSlug(String slug) => switch (slug) {
      'running' => '🏃',
      'cycling' => '🚴',
      'swimming' => '🏊',
      'strength' => '💪',
      'yoga' => '🧘',
      'pilates' => '🤸',
      'hiit' => '⚡',
      'walking' => '🚶',
      'rowing' => '🚣',
      'hiking' => '🥾',
      _ => '🏋️',
    };

const _months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Today" / "Yesterday" / "Wed 13 May" relative to [now].
String relativeDay(DateTime d, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(ref.year, ref.month, ref.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${_weekdays[d.weekday]} ${d.day} ${_months[d.month]}';
}

/// Monday 00:00 of the week containing [d].
DateTime startOfWeek(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// Short month name ("12 Mar 2002" style dates).
String monthName(int month) => _months[month];

/// First instant of the calendar month containing [d] — the Free history
/// cap window (#12: Free sees the current calendar month only).
DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);
