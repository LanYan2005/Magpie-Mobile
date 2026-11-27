import 'package:flutter/material.dart';

/// Design tokens transcribed from yetone/magpie's `internal/gui/assets/app.css`
/// at commit 6346f383. Every value here was read from that file, not invented;
/// keep them in sync if the upstream changes.
///
/// See `docs/ui-rebuild-plan.md` for the mapping table and provenance.
@immutable
class MagpieTokens {
  const MagpieTokens(this.brightness);

  final Brightness brightness;
  bool get isDark => brightness == Brightness.dark;
  Color _c(int light, int dark) => Color(isDark ? dark : light);

  // Surfaces
  Color get bg => _c(0xFFF4F4F6, 0xFF1A1A1E);
  Color get card => _c(0xFFFFFFFF, 0xFF232327);
  Color get card2 => _c(0xFFF9F9FB, 0xFF1F1F23);
  Color get pill => _c(0xFFF1F1F4, 0xFF2D2D33);
  Color get pillHover => _c(0xFFE9E9EE, 0xFF36363D);

  // Lines
  Color get line => _c(0xFFE3E3E8, 0xFF333339);
  Color get line2 => _c(0xFFECECF0, 0xFF2C2C32);

  // Text
  Color get fg => _c(0xFF1C1C21, 0xFFEDEDF1);
  Color get fg2 => _c(0xFF4B4B53, 0xFFB9B9C1);
  Color get muted => _c(0xFF85858D, 0xFF9C9CA6);
  Color get faint => _c(0xFFB9B9C2, 0xFF90909A);
  Color get ctlFg => _c(0xFF63636B, 0xFFA1A1AA);

  // Accent
  Color get accent => _c(0xFF4F46E5, 0xFFA5B4FC);
  Color get accentSoft => _c(0xFFEEEDFD, 0xFF2B2C47);
  Color get accentFg => _c(0xFFFFFFFF, 0xFF14142A);
  Color get sel => _c(0xFFECEBFB, 0xFF33345A);

  // Semantic
  Color get green => _c(0xFF189A58, 0xFF6FD99B);
  Color get greenSoft => _c(0xFFE4F6EC, 0xFF1E3A2B);
  Color get red => _c(0xFFD64545, 0xFFF28B82);
  Color get redSoft => _c(0xFFFBE9E9, 0xFF45272A);
  Color get amber => _c(0xFFB45309, 0xFFF2B544);
  Color get amberSoft => _c(0xFFFBF0DF, 0xFF3F3220);

  // Popover / shadow
  Color get popBg => isDark ? const Color(0xF526262B) : const Color(0xF0FFFFFF);
  List<BoxShadow> get popShadow => isDark
      ? const [
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 44,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x2914161E),
            blurRadius: 44,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x0F14161E),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ];

  // Chart series (--c1..--c7)
  Color get c1 => _c(0xFF4F46E5, 0xFFA5B4FC);
  Color get c2 => _c(0xFF0EA5E9, 0xFF7DD3FC);
  Color get c3 => _c(0xFF10B981, 0xFF6EE7B7);
  Color get c4 => _c(0xFFF59E0B, 0xFFFCD34D);
  Color get c5 => _c(0xFFEC4899, 0xFFF9A8D4);
  Color get c6 => _c(0xFF8B5CF6, 0xFFC4B5FD);
  Color get c7 => _c(0xFF64748B, 0xFF94A3B8);
}

/// Corner radii and sizes from app.css.
abstract final class MagpieMetrics {
  static const listRadius = 12.0;
  static const fieldRadius = 6.0;
  static const segmentRadius = 8.0;
  static const segmentThumbRadius = 6.0;
  static const badgeRadius = 4.0;
  static const popRadius = 12.0;
  static const editorRadius = 10.0;

  /// `.row` min-height, and `body.window .row` when the list breathes.
  static const rowCompact = 40.0;
  static const rowRelaxed = 48.0;
  static const rowGap = 9.0;
  static const rowPadH = 11.0;
  static const rowPadV = 5.0;

  /// `.field` — the pill-shaped value button.
  static const fieldHeight = 25.0;
  static const fieldPadH = 8.0;

  /// `body.web` touch targets.
  static const touchTarget = 44.0;
  static const webIcon = 23.0;
  static const tabBarHeight = 50.5;
}

/// Type ramp from app.css. The app's base is 14 on phones (`body.web`).
abstract final class MagpieType {
  static const double base = 14;
  static const double rowName = 13;
  static const double rowSub = 11.5;
  static const double field = 12.5;
  static const double badge = 9.5;
  static const double tabLabel = 10.5;
  static const double sectionLabel = 11;
}

extension MagpieTokensContext on BuildContext {
  MagpieTokens get tokens => MagpieTokens(Theme.of(this).brightness);
}
