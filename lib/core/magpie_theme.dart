import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'magpie_motion.dart';

/// Semantic colors shared by both platform shells. Jade remains the Magpie
/// accent, while warning, destructive, and informational colors have distinct roles.
@immutable
class MagpiePalette {
  const MagpiePalette(this.brightness, {this.highContrast = false});

  final Brightness brightness;
  final bool highContrast;
  bool get isDark => brightness == Brightness.dark;

  Color _pair(int light, int dark) => Color(isDark ? dark : light);

  // Upstream CSS tokens at yetone/magpie commit 6346f383.
  Color get canvas => _pair(0xFFF4F4F6, 0xFF1A1A1E);
  Color get canvasDeep => _pair(0xFFF1F1F4, 0xFF2D2D33);
  Color get paper => _pair(0xFFFFFFFF, 0xFF232327);
  Color get elevated => _pair(0xFFF9F9FB, 0xFF1F1F23);
  Color get gatewaySurface => _pair(0xFFEEEDFD, 0xFF2B2C47);
  Color get ink => _pair(0xFF1C1C21, 0xFFEDEDF1);
  Color get inkSoft => _pair(0xFF4B4B53, 0xFFB9B9C1);
  Color get muted => _pair(0xFF85858D, 0xFF9C9CA6);
  Color get faint => highContrast ? inkSoft : _pair(0xFFB9B9C2, 0xFF90909A);
  Color get line => highContrast ? lineStrong : _pair(0xFFE3E3E8, 0xFF333339);
  Color get lineStrong => highContrast
      ? _pair(0xFF63636B, 0xFFA1A1AA)
      : _pair(0xFFE3E3E8, 0xFF333339);
  Color get jade => _pair(0xFF4F46E5, 0xFFA5B4FC);
  Color get onJade => _pair(0xFFFFFFFF, 0xFF14142A);
  Color get jadeDeep => _pair(0xFF4F46E5, 0xFFA5B4FC);
  Color get mint => _pair(0xFFEEEDFD, 0xFF2B2C47);
  Color get mintSoft => _pair(0xFFECEBFB, 0xFF33345A);
  Color get cobalt => _pair(0xFF0EA5E9, 0xFF7DD3FC);
  Color get cobaltSoft => _pair(0xFFE0F2FE, 0xFF24364A);
  Color get amber => _pair(0xFFB45309, 0xFFF2B544);
  Color get amberSoft => _pair(0xFFFBF0DF, 0xFF3F3220);
  Color get coral => _pair(0xFFD64545, 0xFFF28B82);
  Color get coralSoft => _pair(0xFFFBE9E9, 0xFF45272A);
  Color get violet => _pair(0xFF8B5CF6, 0xFFC4B5FD);
  Color get violetSoft => _pair(0xFFF1EBFA, 0xFF352B46);
  Color get clay => _pair(0xFFEC4899, 0xFFF9A8D4);
  Color get claySoft => _pair(0xFFFCE7F3, 0xFF3B2635);
  Color get shadow => _pair(0xFF14161E, 0xFF000000);
  Color get brandPlate => const Color(0xFFFFFFFF);
  Color get modalScrim => _pair(0x6614141E, 0x99000000);

  Color interactionOverlay(Set<WidgetState> states, {Color? ink}) {
    if (states.contains(WidgetState.disabled)) return Colors.transparent;
    final color = ink ?? jade;
    if (states.contains(WidgetState.pressed)) {
      return color.withValues(alpha: 0.14);
    }
    if (states.contains(WidgetState.focused)) {
      return color.withValues(alpha: 0.16);
    }
    if (states.contains(WidgetState.hovered)) {
      return color.withValues(alpha: 0.08);
    }
    return Colors.transparent;
  }
}

abstract final class MagpieShape {
  static const field = 6.0;
  static const control = 7.0;
  static const card = 12.0;
  static const panel = 10.0;
  static const dock = 12.0;
  static const sheet = 12.0;
}

extension MagpieThemeContext on BuildContext {
  MagpiePalette get magpie => MagpiePalette(
    Theme.of(this).brightness,
    highContrast: MediaQuery.highContrastOf(this),
  );
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

abstract final class MagpieTheme {
  static ThemeData build(Brightness brightness, {bool highContrast = false}) {
    final colors = MagpiePalette(brightness, highContrast: highContrast);
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.jade,
      onPrimary: colors.onJade,
      primaryContainer: colors.mint,
      onPrimaryContainer: colors.jadeDeep,
      secondary: colors.cobalt,
      onSecondary: colors.isDark ? colors.canvas : Colors.white,
      secondaryContainer: colors.cobaltSoft,
      onSecondaryContainer: colors.cobalt,
      surface: colors.paper,
      onSurface: colors.ink,
      surfaceContainerLow: colors.canvas,
      surfaceContainerHighest: colors.canvasDeep,
      onSurfaceVariant: colors.muted,
      outline: colors.lineStrong,
      outlineVariant: colors.line,
      error: colors.coral,
      onError: colors.isDark ? colors.canvas : Colors.white,
      errorContainer: colors.coralSoft,
      onErrorContainer: colors.coral,
    );

    final textTheme = TextTheme(
      displayLarge: TextStyle(
        color: colors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.7,
      ),
      displayMedium: TextStyle(
        color: colors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.65,
      ),
      headlineLarge: TextStyle(
        color: colors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: colors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.24,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        color: colors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: colors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: TextStyle(color: colors.inkSoft, fontSize: 14, height: 1.45),
      bodyMedium: TextStyle(color: colors.muted, fontSize: 13, height: 1.45),
      bodySmall: TextStyle(color: colors.muted, fontSize: 11.5, height: 1.4),
      labelLarge: TextStyle(
        color: colors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        color: colors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        color: colors.faint,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MagpieShape.control),
    );
    final modalBarrier = highContrast
        ? colors.modalScrim
        : colors.modalScrim.withValues(alpha: 0.82);
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      textTheme: textTheme,
      dividerColor: colors.line,
      splashFactory: NoSplash.splashFactory,
      highlightColor: colors.interactionOverlay(const {WidgetState.pressed}),
      focusColor: colors.interactionOverlay(const {WidgetState.focused}),
      hoverColor: colors.interactionOverlay(const {WidgetState.hovered}),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      platform: defaultTargetPlatform,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colors.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: colors.muted, fontSize: 15),
        floatingLabelStyle: TextStyle(color: colors.muted, fontSize: 13),
        hintStyle: TextStyle(color: colors.faint, fontSize: 15),
        helperStyle: TextStyle(color: colors.muted, fontSize: 13, height: 1.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MagpieShape.field),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MagpieShape.field),
          borderSide: BorderSide(color: colors.lineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MagpieShape.field),
          borderSide: BorderSide(color: colors.jade, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MagpieShape.field),
          borderSide: BorderSide(color: colors.coral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MagpieShape.field),
          borderSide: BorderSide(color: colors.coral, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.jade,
          foregroundColor: colors.onJade,
          minimumSize: const Size(0, 48),
          shape: buttonShape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
          overlayColor: colors.jade.withValues(alpha: 0.10),
          animationDuration: const Duration(milliseconds: 120),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.jade,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: colors.lineStrong),
          shape: buttonShape,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          overlayColor: colors.jade.withValues(alpha: 0.10),
          animationDuration: const Duration(milliseconds: 120),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.jade,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          overlayColor: colors.jade.withValues(alpha: 0.10),
          animationDuration: const Duration(milliseconds: 120),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.lineStrong
              : colors.paper,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.jade
              : colors.canvasDeep,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : colors.lineStrong,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.ink,
        contentTextStyle: TextStyle(
          color: colors.canvas,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        modalBarrierColor: modalBarrier,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MagpieShape.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MagpieShape.panel),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.jade),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const MagpieAndroidPageTransitionsBuilder(),
          TargetPlatform.iOS: const MagpieCupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: const MagpieCupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: const MagpieAndroidPageTransitionsBuilder(),
          TargetPlatform.linux: const MagpieAndroidPageTransitionsBuilder(),
          TargetPlatform.windows: const MagpieAndroidPageTransitionsBuilder(),
        },
      ),
    );
  }
}
