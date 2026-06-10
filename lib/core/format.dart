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
