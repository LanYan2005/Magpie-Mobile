import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/app.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MagpieApp());
    await tester.pumpAndSettle();
  }

  Future<void> switchTab(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('日常界面基准字号清晰且系统文字缩放继续生效', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));

    await switchTab(tester, 'nav-providers');
    final context = tester.element(find.text('Chat Completions'));
    final textTheme = Theme.of(context).textTheme;
    expect(textTheme.bodyLarge?.fontSize, 16);
    expect(textTheme.bodyMedium?.fontSize, 15);
    expect(textTheme.bodySmall?.fontSize, 13);
    expect(textTheme.labelMedium?.fontSize, 13);
    expect(textTheme.labelSmall?.fontSize, 12);
    expect(
      tester
          .widget<MediaQuery>(find.byType(MediaQuery).first)
          .data
          .textScaler
          .scale(16),
      16,
    );
    expect(tester.takeException(), isNull);

    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('小屏手机与放大字体下主要页面不溢出', (tester) async {
    await pumpApp(tester, size: const Size(320, 568), textScale: 1.25);

    expect(find.text('本机网关已停止'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await switchTab(tester, 'nav-providers');
    expect(find.text('Chat Completions'), findsOneWidget);
    expect(find.byKey(const ValueKey('gateway-route-gemini')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gateway-route-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gateway-route-endpoint')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    await switchTab(tester, 'nav-agents');
    expect(find.text('Claude Code'), findsOneWidget);
    await tester.ensureVisible(find.text('Claude Code'));
    await tester.tap(find.text('Claude Code'));
    await tester.pumpAndSettle();
    expect(find.text('运行时与接入方式'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    await switchTab(tester, 'nav-resources');
    expect(find.text('code-review'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('resource-tab-mcp')));
    await tester.tap(find.byKey(const ValueKey('resource-tab-mcp')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('add-mcp-button')));
    expect(find.byKey(const ValueKey('add-mcp-button')), findsOneWidget);

    await switchTab(tester, 'nav-overview');
    await tester.tap(find.byKey(const ValueKey('open-settings-button')));
    await tester.pumpAndSettle();
    expect(find.text('平台适配清单'), findsOneWidget);
  });

  testWidgets('导航转场短促且能切页', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MagpieApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-providers')));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Chat Completions'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Chat Completions'), findsOneWidget);
  });

  testWidgets('关闭系统动画偏好后导航与按压状态即时完成', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const MagpieApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-providers')));
    await tester.pump();
    expect(find.text('Chat Completions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('导航玻璃层在深色、减弱透明度偏好下回退为实色', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const MagpieApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dock-selection')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('深色模式下导航和 Gateway 语义色清晰', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const MagpieApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.darkTheme?.brightness, Brightness.dark);
    expect(find.text('Gateway'), findsOneWidget);
    expect(find.text('本机网关已停止'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏与默认字体下主要页面保持完整', (tester) async {
    await pumpApp(tester, size: const Size(430, 932));

    await switchTab(tester, 'nav-providers');
    await tester.tap(find.text('Chat Completions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gateway-route-endpoint')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await switchTab(tester, 'nav-resources');
    expect(find.text('code-review'), findsOneWidget);
  });
}
