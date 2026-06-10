import 'package:flutter/material.dart';

/// Brand palette — single source of truth, mirrors docs/reference/palette.md.
/// Dark-mode app; never pure black (`bg` is intentionally #111210).
abstract final class AppColors {
  static const bg = Color(0xFF111210); // primary background (deepest layer)
  static const surface = Color(0xFF1E1F1B); // cards, raised elements
  static const surface2 = Color(0xFF252620); // higher elevation / hover
  static const ink = Color(0xFFEEEEE8); // primary text / headings
  static const muted = Color(0xFF8A8A84); // secondary text (AA on surface)
  static const faint = Color(0xFF333330); // dividers only — never text
  static const accent = Color(0xFFB8FF00); // primary CTA / brand accent
  static const accentDim = Color(0xFF8CC400); // accent hover / pressed
  static const danger = Color(0xFFFF2D55); // errors / destructive
  static const info = Color(0xFF00B4FF); // info / share / recovery
  static const gold = Color(0xFFFFD700); // #1 leaderboard rank ONLY
}
