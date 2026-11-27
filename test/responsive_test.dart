import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/app.dart';
import 'package:magpie_mobile/gateway/gateway_settings.dart';
import 'package:magpie_mobile/gateway/gateway_upstream.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const sections = [
    ('agents', 'Agent'),
    ('sessions', '会话'),
    ('resources', '资源库'),
    ('artifacts', 'Artifacts'),
    ('providers', '供应商'),
    ('routing', '路由'),
    ('routingGroups', '路由组'),
    ('gateway', '网关'),
    ('usage', '用量'),
    ('redaction', '脱敏'),
    ('plugins', '插件'),
  ];
  const mobileSections = [
    'agents',
    'resources',
    'providers',
    'gateway',
    'plugins',
  ];
  final toggle = find.byKey(const ValueKey('sidebar-toggle'));
  final settings = find.byKey(const ValueKey('open-settings-button'));
  final sidebar = find.byKey(const ValueKey('section-sidebar'));
  final scrim = find.byKey(const ValueKey('sidebar-scrim'));

  Future<SharedPreferences> preferences() async {
    SharedPreferences.setMockInitialValues({
      GatewaySettings.catalogKey: jsonEncode({
        'version': 1,
        'providers': [
          {
            'id': 'test-provider',
            'name': 'Test Provider',
            'enabled': true,
            'agentIds': <String>[],
            'accounts': [
              {
                'id': 'test-account',
                'name': 'Primary',
                'protocol': GatewayProtocol.chat.name,
                'endpoint': 'https://api.example.com/v1/chat/completions',
                'requiresKey': false,
                'models': ['test-model'],
              },
            ],
          },
        ],
        'selected': {GatewayProtocol.chat.name: 'test-account'},
      }),
    });
    return SharedPreferences.getInstance();
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
    Brightness? brightness,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    if (brightness != null) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    }
    await tester.pumpWidget(MagpieApp(preferences: await preferences()));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> selectMobile(WidgetTester tester, String id) =>
      tap(tester, find.byKey(ValueKey('nav-$id')));

  Future<void> openDrawer(WidgetTester tester) async {
    if (scrim.evaluate().isEmpty) await tap(tester, toggle);
  }

  void expectPrimaryFocus(WidgetTester tester) {
    expect(
      tester.widget<IconButton>(toggle).focusNode!.hasPrimaryFocus,
      isTrue,
    );
  }

  testWidgets('320/390 手机底栏固定五项，抽屉按序覆盖 11 栏', (tester) async {
    for (final size in [const Size(320, 568), const Size(390, 844)]) {
      await pumpApp(tester, size: size, textScale: size.width == 320 ? 2 : 1);
      expect(sidebar, findsNothing);
      expect(
        find.byKey(const ValueKey('mobile-bottom-navigation')),
        findsOneWidget,
      );
      for (final (id, _) in sections) {
        expect(find.byKey(ValueKey('sidebar-$id')), findsNothing);
      }
      var previousRight = double.negativeInfinity;
      for (final id in mobileSections) {
        final item = find.byKey(ValueKey('nav-$id'));
        expect(item, findsOneWidget);
        expect(item.hitTestable(), findsOneWidget);
        final rect = tester.getRect(item);
        expect(rect.left, greaterThanOrEqualTo(previousRight));
        expect(rect.size.height, greaterThanOrEqualTo(44));
        previousRight = rect.right;
      }
      expect(tester.getSize(toggle).shortestSide, greaterThanOrEqualTo(44));
      expect(tester.getSize(settings).shortestSide, greaterThanOrEqualTo(44));

      await openDrawer(tester);
      expect(scrim, findsOneWidget);
      for (final (id, _) in sections) {
        final item = find.byKey(ValueKey('sidebar-$id'));
        expect(item, findsOneWidget);
        await tester.ensureVisible(item);
        await tester.pumpAndSettle();
        expect(item.hitTestable(), findsOneWidget);
        expect(tester.getSize(item).shortestSide, greaterThanOrEqualTo(44));
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('sidebar-routingGroups')),
      );
      await tap(tester, find.byKey(const ValueKey('sidebar-routingGroups')));
      expect(find.text('路由组管理尚未接入移动端。'), findsOneWidget);
      expect(scrim, findsNothing);
      expectPrimaryFocus(tester);
      expect(find.byKey(const ValueKey('nav-routingGroups')), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('1024 宽屏停靠侧栏覆盖 11 栏，折叠为横向栏目', (tester) async {
    await pumpApp(tester, size: const Size(1024, 768));
    expect(sidebar, findsOneWidget);
    for (final (id, _) in sections) {
      expect(find.byKey(ValueKey('sidebar-$id')), findsOneWidget);
      expect(find.byKey(ValueKey('nav-$id')), findsNothing);
    }
    await tap(tester, toggle);
    expect(sidebar, findsNothing);
    for (final (id, _) in sections) {
      final item = find.byKey(ValueKey('nav-$id'));
      expect(item, findsOneWidget);
      expect(item.hitTestable(), findsOneWidget);
      expect(tester.getSize(item).height, greaterThanOrEqualTo(44));
    }
    await tap(tester, find.byKey(const ValueKey('nav-routing')));
    expect(find.text('规则路由尚未实现。可在「供应商」为每种协议选择一个网关账号。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏抽屉遮罩、返回键和 Escape 关闭后恢复焦点', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    for (final close in <Future<void> Function()>[
      () => tap(tester, toggle),
      () async {
        await tester.tapAt(tester.getTopRight(scrim) + const Offset(-10, 30));
        await tester.pumpAndSettle();
      },
      () async {
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
      },
      () async {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      },
    ]) {
      await openDrawer(tester);
      expect(scrim, findsOneWidget);
      await close();
      expect(scrim, findsNothing);
      expect(sidebar, findsNothing);
      expectPrimaryFocus(tester);
    }
  });

  testWidgets('子栏目、资源滚动位置跨切页及方向变化保持', (tester) async {
    await pumpApp(tester, size: const Size(390, 640));
    await selectMobile(tester, 'resources');
    final mcp = find.byKey(const ValueKey('resource-tab-mcp'));
    await tap(tester, mcp);
    final addMcp = find.byKey(const ValueKey('add-mcp-button'));
    await tester.ensureVisible(addMcp);
    await tester.pumpAndSettle();
    final scroll = Scrollable.of(tester.element(addMcp)).position;
    final originalOffset = scroll.pixels;
    expect(originalOffset, greaterThan(0));

    await selectMobile(tester, 'providers');
    await selectMobile(tester, 'resources');
    expect(scroll.pixels, originalOffset);
    expect(find.byKey(const ValueKey('resource-tab-mcp')), findsOneWidget);

    tester.view.physicalSize = const Size(900, 600);
    await tester.pumpAndSettle();
    expect(sidebar, findsOneWidget);
    expect(find.byKey(const ValueKey('resource-tab-mcp')), findsOneWidget);
    expect(Scrollable.of(tester.element(addMcp)).position, same(scroll));
    tester.view.physicalSize = const Size(390, 640);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add-mcp-button')), findsOneWidget);
    expect(scroll.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏可以从供应商目录打开并滚动自定义编辑卡', (tester) async {
    await pumpApp(tester, size: const Size(320, 568), textScale: 1.25);
    await selectMobile(tester, 'providers');
    await tap(tester, find.byKey(const ValueKey('provider-add')));
    expect(find.text('添加供应商'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('provider-directory-custom')));
    expect(find.text('自定义供应商'), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-account-name')), findsNothing);
    expect(
      find.byKey(const ValueKey('provider-account-protocol')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('gateway-route-base-url')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('provider-account-models')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('provider-account-selected')),
      findsNothing,
    );
    expect(find.text('用于此协议的网关转发'), findsNothing);
    expect(find.byKey(const ValueKey('gateway-route-key')), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-name')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('provider-account-editor-scroll')),
      findsOneWidget,
    );
    final editorScroll = find.byKey(
      const ValueKey('provider-account-editor-scroll'),
    );
    await tester.drag(editorScroll, const Offset(0, -2400));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('gateway-route-save')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 窄屏放大文字后 Agent 控件纵向排列且可操作', (tester) async {
    await pumpApp(tester, size: const Size(320, 568), textScale: 2);
    final agentName = find.byKey(const ValueKey('agent-name-agent-claude'));
    final model = find.byKey(const ValueKey('agent-model-agent-claude'));
    final access = find.byKey(const ValueKey('agent-access-agent-claude'));
    final details = find.byKey(const ValueKey('agent-details-agent-claude'));
    expect(model, findsOneWidget);
    expect(access, findsOneWidget);
    expect(details, findsOneWidget);
    expect(
      tester.getTopLeft(model).dy,
      greaterThan(tester.getTopLeft(agentName).dy),
    );
    await tap(tester, model);
    expect(
      find.byKey(const ValueKey('agent-model-field')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('导航转场启动并完成，减弱动画偏好即时切页', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('nav-providers')));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Test Provider'), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-transition')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Test Provider'), findsOneWidget);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.tap(find.byKey(const ValueKey('nav-agents')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('agent-name-agent-claude')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('深色模式下导览和网关状态内容可见', (tester) async {
    await pumpApp(
      tester,
      size: const Size(390, 844),
      brightness: Brightness.dark,
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.darkTheme?.brightness, Brightness.dark);
    await selectMobile(tester, 'gateway');
    expect(find.text('本机监听器'), findsOneWidget);
    expect(find.text('本机网关已停止'), findsOneWidget);
    final context = tester.element(find.text('本机网关已停止'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });
}
