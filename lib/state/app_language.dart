import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/magpie_l10n.dart';

/// Stores only the UI language, not any of the demo data or credentials.
class AppLanguage extends ValueNotifier<Locale> {
  AppLanguage(this._preferences)
    : super(
        _preferences?.get(_key) == 'en'
            ? MagpieL10n.english
            : MagpieL10n.chinese,
      );

  static const _key = 'magpie.ui_language';
  final SharedPreferences? _preferences;
  Future<void> _pendingWrite = Future<void>.value();

  Future<bool> select(Locale locale) async {
    value = locale;
    // Serialize writes so a quick sequence of taps persists the last choice.
    final write = _pendingWrite.then((_) async {
      final preferences = _preferences;
      if (preferences == null) return false;
      return preferences.setString(_key, locale.languageCode);
    });
    _pendingWrite = write.then<void>((_) {}, onError: (Object _) {});
    try {
      final saved = await write;
      // Don't report a stale failure after the user has chosen another language.
      return saved || value.languageCode != locale.languageCode;
    } on Exception {
      return value.languageCode != locale.languageCode;
    }
  }
}

class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    required this.language,
    required super.child,
    super.key,
  });

  final AppLanguage language;

  static AppLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageScope>()!.language;

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) =>
      oldWidget.language != language;
}
