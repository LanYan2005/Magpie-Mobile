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

  Color get canvas => _pair(0xFFF3F5F4, 0xFF101412);
  Color get canvasDeep => _pair(0xFFE7EDE9, 0xFF28312C);
  Color get paper => _pair(0xFFFCFDFC, 0xFF19211D);
  Color get elevated => _pair(0xFFFEFFFE, 0xFF232D27);
  Color get gatewaySurface => _pair(0xFFE7F2EC, 0xFF20322A);
  Color get ink => _pair(0xFF14201A, 0xFFF1F7F3);
  Color get inkSoft => _pair(0xFF30463B, 0xFFD6E5DB);
  Color get muted => _pair(0xFF4E6257, 0xFFB0C1B6);
  Color get faint => highContrast ? inkSoft : _pair(0xFF596D62, 0xFFA3B6AA);
  Color get line => highContrast ? lineStrong : _pair(0xFFDCE6E0, 0xFF35443B);
  Color get lineStrong => highContrast
      ? _pair(0xFF677E70, 0xFF889F91)
      : _pair(0xFFBECDC4, 0xFF54665B);
  Color get jade => _pair(0xFF0E725C, 0xFF82D8BB);
  Color get onJade => _pair(0xFFFFFFFF, 0xFF122D25);
  Color get jadeDeep => _pair(0xFF084C3E, 0xFFA8E7D2);
  Color get mint => _pair(0xFFD3EDE1, 0xFF214238);
  Color get mintSoft => _pair(0xFFEAF7F0, 0xFF20332D);
  Color get cobalt => _pair(0xFF3359B2, 0xFFADC4FF);
  Color get cobaltSoft => _pair(0xFFEAF0FC, 0xFF253249);
  Color get amber => _pair(0xFF855610, 0xFFF6C875);
  Color get amberSoft => _pair(0xFFFFF3DB, 0xFF3A3020);
  Color get coral => _pair(0xFFA53D31, 0xFFFFAA9E);
  Color get coralSoft => _pair(0xFFFBEAE5, 0xFF412C2A);
  Color get violet => _pair(0xFF6B4DA8, 0xFFCDB6FA);
  Color get violetSoft => _pair(0xFFF1EBFA, 0xFF352B46);
  Color get clay => _pair(0xFF955020, 0xFFF1B488);
  Color get claySoft => _pair(0xFFF7E9DD, 0xFF3B2D25);
  Color get shadow => _pair(0xFF173A34, 0xFF000000);
  Color get brandPlate => const Color(0xFFFCFDFC);
  Color get modalScrim => _pair(0x55101B15, 0x99080C0A);

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
  static const field = 14.0;
  static const control = 16.0;
  static const card = 22.0;
  static const panel = 28.0;
  static const dock = 32.0;
  static const sheet = 32.0;
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
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.7,
      ),
      displayMedium: TextStyle(
        color: colors.ink,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.65,
      ),
      headlineLarge: TextStyle(
        color: colors.ink,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: colors.ink,
        fontSize: 23,
        fontWeight: FontWeight.w700,
        height: 1.24,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        color: colors.ink,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: colors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: TextStyle(color: colors.inkSoft, fontSize: 16, height: 1.55),
      bodyMedium: TextStyle(color: colors.muted, fontSize: 15, height: 1.55),
      bodySmall: TextStyle(color: colors.muted, fontSize: 13, height: 1.5),
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
        helperStyle: TextStyle(
          color: colors.muted,
          fontSize: 13,
          height: 1.45,
        ),
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
