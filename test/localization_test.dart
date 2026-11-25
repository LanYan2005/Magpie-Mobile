import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('默认使用中文，保存英文偏好，并在切回中文时立即更新', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(dispatcher.clearLocalesTestValue);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Locale? appLocale() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale;

    Future<void> mountApp() async {
      await tester.pumpWidget(MagpieApp(preferences: prefs));
      await tester.pumpAndSettle();
    }

    Future<void> openSettings() async {
      await tester.tap(find.byKey(const ValueKey('open-settings-button')));
      await tester.pumpAndSettle();
    }

    await mountApp();
    expect(appLocale(), const Locale('zh'));
    expect(find.text('概览'), findsWidgets);
    expect(find.text('Overview'), findsNothing);

    await openSettings();
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('语言 / Language'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('language-en')));
    await tester.pumpAndSettle();
    expect(appLocale(), const Locale('en'));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language / 语言'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await prefs.reload();
    await mountApp();
    expect(appLocale(), const Locale('en'));
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('概览'), findsNothing);

    await openSettings();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('language-zh')));
    await tester.pump();
    expect(appLocale(), const Locale('zh'));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('语言 / Language'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('概览'), findsWidgets);
    expect(find.text('Overview'), findsNothing);
  });
}
