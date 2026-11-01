import 'package:flutter/material.dart';

/// Verdant palette. Ink + paper neutrals with a moss primary and a sharp lime
/// highlight. Accent is swappable at runtime (see [AccentOption]).
class VerdantColors {
  VerdantColors._();

  // Neutrals — light
  static const paper = Color(0xFFF3F0E8);
  static const paperDeep = Color(0xFFE9E4D8);
  static const card = Color(0xFFFBFAF6);
  static const ink = Color(0xFF0F1A14);
  static const inkSoft = Color(0xFF2A352E);
  static const muted = Color(0xFF6B7368);
  static const line = Color(0xFFE0DBCF);

  // Neutrals — dark
  static const night = Color(0xFF0B110D);
  static const nightCard = Color(0xFF151E18);
  static const nightRaised = Color(0xFF1C2820);
  static const nightLine = Color(0xFF26332A);
  static const mist = Color(0xFFEEF2EA);
  static const mistMuted = Color(0xFF94A096);

  // Brand
  static const moss = Color(0xFF1F5135);
  static const fern = Color(0xFF3E8A57);
  static const lime = Color(0xFFC6F36B);
  static const terracotta = Color(0xFFE07A4F);
  static const sun = Color(0xFFF5C14B);
  static const blossom = Color(0xFFF2A3BF);
  static const danger = Color(0xFFD9483B);

  /// Soft backdrops used behind plants, keyed by pot id.
  static const potBackdrops = <String, List<Color>>{
    'terracotta': [Color(0xFFF7E3D6), Color(0xFFF1D2BF)],
    'ivory': [Color(0xFFEDEBE3), Color(0xFFE2DED2)],
    'stone': [Color(0xFFE6E7E2), Color(0xFFD6D8D1)],
    'sage': [Color(0xFFE2EDDD), Color(0xFFCFE0C8)],
    'midnight': [Color(0xFFDCE1EC), Color(0xFFC7CEDF)],
    'blush': [Color(0xFFF8E4E0), Color(0xFFF0D0C9)],
  };

  static const potBackdropsDark = <String, List<Color>>{
    'terracotta': [Color(0xFF2A1F19), Color(0xFF221812)],
    'ivory': [Color(0xFF22241F), Color(0xFF1A1C18)],
    'stone': [Color(0xFF202321), Color(0xFF191B1A)],
    'sage': [Color(0xFF1C271E), Color(0xFF162019)],
    'midnight': [Color(0xFF1A1F2C), Color(0xFF141824)],
    'blush': [Color(0xFF2A1F20), Color(0xFF221819)],
  };
}

/// Accent colours the user (or admin) can pick in Appearance settings.
enum AccentOption {
  moss('Moss', Color(0xFF1F5135), Color(0xFFC6F36B)),
  fern('Fern', Color(0xFF2F7A4B), Color(0xFFB8F0C2)),
  terracotta('Terracotta', Color(0xFFB4532C), Color(0xFFFFC9A8)),
  ocean('Ocean', Color(0xFF1E4E6B), Color(0xFF9EE6F0)),
  plum('Plum', Color(0xFF5A2E57), Color(0xFFF5B3E1));

  const AccentOption(this.label, this.primary, this.highlight);
  final String label;
  final Color primary;
  final Color highlight;
}

extension ColorAlpha on Color {
  /// Opacity helper that works on every Flutter 3.x version.
  Color o(double opacity) => withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}
