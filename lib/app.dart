import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gateway/gateway_controller.dart';
import 'gateway/gateway_scope.dart';
import 'core/magpie_l10n.dart';
import 'core/magpie_theme.dart';
import 'screens/app_shell.dart';
import 'state/app_language.dart';
import 'state/magpie_store.dart';

class MagpieApp extends StatefulWidget {
  const MagpieApp({this.preferences, super.key});

  final SharedPreferences? preferences;

  @override
  State<MagpieApp> createState() => _MagpieAppState();
}

class _MagpieAppState extends State<MagpieApp> {
  late final MagpieStore _store = MagpieStore();
  late final AppLanguage _language = AppLanguage(widget.preferences);
  late final GatewayController _gateway = GatewayController(
    preferences: widget.preferences,
  );

  @override
  void dispose() {
    _gateway.dispose();
    _language.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GatewayScope(
      controller: _gateway,
      child: MagpieScope(
        store: _store,
        child: AppLanguageScope(
          language: _language,
          child: ValueListenableBuilder<Locale>(
            valueListenable: _language,
            builder: (context, locale, _) => _buildApp(locale),
          ),
        ),
      ),
    );
  }

  Widget _buildApp(Locale locale) {
    return MaterialApp(
      locale: locale,
      supportedLocales: MagpieL10n.supportedLocales,
      localizationsDelegates: const [
        MagpieL10n.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      title: 'Magpie',
      debugShowCheckedModeBanner: false,
      theme: MagpieTheme.build(Brightness.light),
      darkTheme: MagpieTheme.build(Brightness.dark),
      highContrastTheme: MagpieTheme.build(
        Brightness.light,
        highContrast: true,
      ),
      highContrastDarkTheme: MagpieTheme.build(
        Brightness.dark,
        highContrast: true,
      ),
      themeAnimationDuration: Duration.zero,
      home: const AppShell(),
      builder: (context, child) {
        final colors = context.magpie;
        final overlays = colors.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlays.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: colors.canvas,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
