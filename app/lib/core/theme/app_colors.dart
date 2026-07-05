import 'package:flutter/material.dart';

/// Brand palette — single source of truth, mirrors docs/reference/palette.md.
/// Light-mode app on a white base; accents are bright and high-contrast so text,
/// icons and stat numbers stay readable on white (the accent is used as a
/// foreground colour, not just a fill, so it is intentionally deep + saturated).
abstract final class AppColors {
  static const bg = Color(0xFFF6F7FB); // primary background (soft white) + on-accent foreground
  static const surface = Color(0xFFFFFFFF); // cards, raised elements (pure white, pops over bg)
  static const surface2 = Color(0xFFEDEFF4); // higher elevation / hover
  static const ink = Color(0xFF15161B); // primary text / headings (near-black, ~16:1 on white)
  static const muted = Color(0xFF2B313B); // secondary text (deep slate, ~13:1 on white)
  static const faint = Color(0xFFE4E7EC); // dividers / hairline borders only — never text
  static const accent = Color(0xFF7B2FF7); // primary CTA / brand accent (electric violet)
  static const accentDim = Color(0xFF6A1FE0); // accent hover / pressed
  static const danger = Color(0xFFE11D48); // negative / destructive / errors (vivid rose) — readable as text
  static const info = Color(0xFF2563EB); // info / share / recovery (vivid blue)
  static const gold = Color(0xFFFFC400); // #1 leaderboard rank ONLY

  /// Uniform soft elevation for content cards — apply as `boxShadow:` on a card's
  /// BoxDecoration so every card lifts off the background the same way.
  static const cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // --- Semantic state (meaning, not decoration) ---
  static const success = Color(0xFF047857); // positive / up-trend / completed — TEXT green (emerald, ~5.5:1)
  static const successBright = Color(0xFF10B981); // vivid green for FILLS/badges (with ink text) — never small text

  // --- Premium tier (gold). `premium` = fills/badges (with ink text); `premiumText` = text/borders on white ---
  static const premium = Color(0xFFF59E0B); // premium badge/button FILL (amber) — pair with ink text
  static const premiumText = Color(0xFFB45309); // premium text / links / borders on white (deep amber, ~5:1)

  // --- Metric colours (workout stats: large values + metric icons; all ≥4.5:1 so they read on white) ---
  static const mDistance = Color(0xFF2563EB); // distance / km — blue
  static const mPace = Color(0xFF0F766E); // pace / speed — teal
  static const mDuration = Color(0xFF4F46E5); // time / active minutes — indigo
  static const mHeart = Color(0xFFDB2777); // heart rate — pink
  static const mEnergy = Color(0xFFC2410C); // calories / energy — orange

  /// Maps a metric's short label (e.g. 'KM', 'AVG HR', 'CALORIES') to its
  /// standard colour, so the same metric reads the same hue on every screen.
  /// Returns [ink] for anything unrecognised (keeps it readable by default).
  static Color metricColor(String label) {
    final l = label.toUpperCase();
    if (l.contains('PACE') || l.startsWith('/')) return mPace; // '/KM' before 'KM'
    if (l.contains('KM') || l.contains('DIST') || l.contains('STEP')) return mDistance;
    if (l.contains('HR') || l.contains('HEART') || l.contains('BPM')) return mHeart;
    if (l.contains('CAL') || l.contains('ENERG')) return mEnergy; // KCAL / CALORIES
    if (l.contains('SESSION') || l.contains('WORKOUT')) return success;
    if (l.contains('MIN') || l.contains('TIME') || l.contains('DUR')) return mDuration;
    return ink;
  }
}
