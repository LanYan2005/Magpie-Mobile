import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/app.dart';
import 'package:magpie_mobile/core/magpie_l10n.dart';
import 'package:magpie_mobile/gateway/gateway_controller.dart';
import 'package:magpie_mobile/gateway/gateway_scope.dart';
import 'package:magpie_mobile/gateway/gateway_settings.dart';
import 'package:magpie_mobile/gateway/gateway_upstream.dart';
import 'package:magpie_mobile/screens/gateway_page.dart';
import 'package:magpie_mobile/state/magpie_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LoopbackHttpOverrides extends HttpOverrides {}

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    SharedPreferences? preferences,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MagpieApp(preferences: preferences));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('自定义供应商 Fetch models 与 Test 发送真实协议请求', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final server = await tester.runAsync(
      () => HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    expect(server, isNotNull);
    addTearDown(() => tester.runAsync(() => server!.close(force: true)));
    final requests = <HttpRequest>[];
    server!.listen((request) async {
      requests.add(request);
      request.response.headers.contentType = ContentType.json;
      if (request.method == 'GET') {
        request.response.write(
          jsonEncode({
            'data': [
              {'id': 'fixture-live-model'},
            ],
          }),
        );
      } else {
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        expect(body['model'], 'fixture-live-model');
        request.response.write(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'OK'},
              },
            ],
          }),
        );
      }
      await request.response.close();
    });
    await pumpApp(tester, preferences: preferences);
    await tapKey(tester, 'nav-providers');
    await tapKey(tester, 'provider-add');
    expect(
      find.byKey(const ValueKey('provider-directory-custom')),
      findsOneWidget,
    );
    await tapKey(tester, 'provider-directory-custom');
    expect(
      find.byKey(const ValueKey('provider-account-protocol')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('gateway-route-base-url')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('gateway-route-key')), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('provider-detect-apis')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const ValueKey('provider-name')),
      'Live fixture',
    );
    await tester.enterText(
      find.byKey(const ValueKey('gateway-route-base-url')),
      'http://127.0.0.1:${server.port}/v1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('gateway-route-key')),
      'fixture-secret',
    );
    Future<void> runProbe(String key) async {
      final target = find.byKey(ValueKey(key));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final button = tester.widget<OutlinedButton>(target);
          button.onPressed!();
          for (var i = 0; i < 200; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
            if (tester.widget<OutlinedButton>(target).onPressed != null) return;
          }
          fail('Provider probe did not finish');
        }, _LoopbackHttpOverrides());
      });
      await tester.pumpAndSettle();
    }

    await runProbe('provider-fetch-models');
    expect(find.textContaining('已获取 1 个模型'), findsOneWidget);
    expect(find.text('fixture-live-model'), findsWidgets);
    expect(requests.map((request) => request.uri.path), ['/v1/models']);
    await runProbe('provider-test-model');
    expect(find.textContaining('模型已成功响应测试请求'), findsOneWidget);
    expect(requests.map((request) => request.uri.path), [
      '/v1/models',
      '/v1/chat/completions',
    ]);
    expect(requests.map((request) => request.headers.value('authorization')), [
      'Bearer fixture-secret',
      'Bearer fixture-secret',
    ]);
    final keyField = tester.widget<TextField>(
      find.byKey(const ValueKey('gateway-route-key')),
    );
    expect(keyField.obscureText, isTrue);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data ?? widget.textSpan?.toPlainText() ?? '').contains(
              'fixture-secret',
            ),
      ),
      findsNothing,
    );
    await tapKey(tester, 'gateway-route-save');
    expect(find.text('Live fixture'), findsOneWidget);
    expect(find.textContaining('fixture-secret'), findsNothing);
    final catalog = ProviderCatalog.decode(
      jsonDecode(preferences.getString(GatewaySettings.catalogKey)!),
      allowReferences: true,
    );
    expect(catalog.providers.single.accounts.single.models, [
      'fixture-live-model',
    ]);
    expect(
      catalog.selected[GatewayProtocol.chat],
      catalog.providers.single.accounts.single.id,
    );
    expect(
      preferences.getString(GatewaySettings.catalogKey),
      isNot(contains('fixture-secret')),
    );
  });

  testWidgets('预设供应商只输入名称与密钥并使用目录协议地址', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await pumpApp(tester, preferences: preferences);
    await tapKey(tester, 'nav-providers');
    await tapKey(tester, 'provider-add');
    await tapKey(tester, 'provider-preset-openai');
    expect(find.text('OpenAI'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('provider-account-protocol')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('provider-preset-base-url')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('provider-account-models')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('gateway-route-key')),
      'fixture-preset-secret',
    );
    await tapKey(tester, 'gateway-route-save');
    expect(find.text('OpenAI'), findsOneWidget);
    final catalog = ProviderCatalog.decode(
      jsonDecode(preferences.getString(GatewaySettings.catalogKey)!),
      allowReferences: true,
    );
    final account = catalog.providers.single.accounts.single;
    expect(account.protocol, GatewayProtocol.chat);
    expect(
      account.endpoint,
      Uri.parse('https://api.openai.com/v1/chat/completions'),
    );
    expect(catalog.selected[GatewayProtocol.chat], account.id);
    expect(
      preferences.getString(GatewaySettings.catalogKey),
      isNot(contains('fixture-preset-secret')),
    );
  });

  testWidgets('System One 的获取模型与测试清晰禁用且可手填保存', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await pumpApp(tester, preferences: preferences);
    await tapKey(tester, 'nav-providers');
    await tapKey(tester, 'provider-add');
    await tapKey(tester, 'provider-directory-custom');
    await tapKey(tester, 'provider-api-systemOne');
    await tester.enterText(
      find.byKey(const ValueKey('provider-name')),
      'Decision API',
    );
    await tester.enterText(
      find.byKey(const ValueKey('gateway-route-base-url')),
      'https://api.example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('gateway-route-key')),
      'fixture-decision-key',
    );
    await tester.enterText(
      find.byKey(const ValueKey('provider-account-models')),
      'router-model',
    );
    final fetch = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('provider-fetch-models')),
    );
    final test = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('provider-test-model')),
    );
    expect(fetch.onPressed, isNull);
    expect(test.onPressed, isNull);
    expect(find.textContaining('System One 的获取模型与测试尚未接入'), findsOneWidget);
    await tapKey(tester, 'gateway-route-save');
    expect(find.text('Decision API'), findsOneWidget);
    expect(
      preferences.getString(GatewaySettings.catalogKey),
      isNot(contains('fixture-decision-key')),
    );
  });

  testWidgets('Agent 是默认首屏，设置仍可从共享工具栏打开', (tester) async {
    await pumpApp(tester);

    expect(find.text('Claude Code'), findsOneWidget);
    expect(find.text('本机网关已停止'), findsNothing);
    expect(find.byKey(const ValueKey('nav-agents')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Android + iOS\n共用界面'), findsOneWidget);
    expect(find.text('平台适配尚未接入'), findsOneWidget);
    expect(find.text('平台适配清单'), findsOneWidget);
    expect(find.text('Keychain / Keystore'), findsOneWidget);
  });

  testWidgets('亮色主题适配 Magpie 语义色并保留导航名', (tester) async {
    await pumpApp(tester);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.highContrastTheme, isNotNull);
    expect(app.highContrastDarkTheme, isNotNull);
    expect(find.byKey(const ValueKey('nav-resources')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-gateway')), findsOneWidget);
    expect(find.text('本机网关已停止'), findsNothing);
  });

  testWidgets('从供应商详情配置账号并保存，密钥独立存储且不回显', (tester) async {
    const providerName = '团队 API';
    const renamedProviderName = '团队 API 改名';
    final accountName = GatewayProtocol.chat.label;
    const baseUrl = 'https://api.example.com/v1';
    const endpoint = '$baseUrl/chat/completions';
    const model = 'fixture-chat-model';
    const apiKey = 'fixture-key-024';
    const storage = FlutterSecureStorage();
    FlutterSecureStorage.setMockInitialValues({});
    addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await pumpApp(tester, preferences: preferences);

    await tapKey(tester, 'nav-providers');
    expect(find.text('还没有供应商'), findsOneWidget);
    await tapKey(tester, 'provider-add');
    expect(find.text('添加供应商'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('还没有供应商'), findsOneWidget);
    expect(preferences.getString(GatewaySettings.catalogKey), isNull);
    await tapKey(tester, 'provider-add');
    await tapKey(tester, 'provider-directory-custom');
    await tester.enterText(
      find.byKey(const ValueKey('provider-name')),
      providerName,
    );
    expect(find.byKey(const ValueKey('provider-account-name')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('gateway-route-base-url')),
      baseUrl,
    );
    await tester.enterText(
      find.byKey(const ValueKey('provider-account-models')),
      model,
    );
    final keyField = find.byKey(const ValueKey('gateway-route-key'));
    expect(tester.widget<TextField>(keyField).obscureText, isTrue);
    await tester.ensureVisible(keyField);
    await tester.enterText(keyField, apiKey);
    for (final protocol in GatewayProtocol.values) {
      final option = tester.widget<ChoiceChip>(
        find.byKey(ValueKey('provider-api-${protocol.name}')),
      );
      expect(option.selected, protocol == GatewayProtocol.chat);
    }
    expect(
      find.byKey(const ValueKey('provider-account-selected')),
      findsNothing,
    );
    await tapKey(tester, 'gateway-route-save');

    final providerRow = find.text(providerName);
    expect(providerRow, findsOneWidget);
    expect(find.text('账号与协议'), findsNothing);
    expect(find.text('网关使用中'), findsNothing);
    final catalogBeforeRename = ProviderCatalog.decode(
      jsonDecode(preferences.getString(GatewaySettings.catalogKey)!),
      allowReferences: true,
    );
    expect(catalogBeforeRename.providers, hasLength(1));
    expect(catalogBeforeRename.providers.single.accounts, hasLength(1));
    expect(catalogBeforeRename.selected, {
      GatewayProtocol.chat:
          catalogBeforeRename.providers.single.accounts.single.id,
    });
    await tester.tap(providerRow);
    await tester.pumpAndSettle();
    expect(find.text('账号与协议'), findsOneWidget);
    expect(find.text(accountName), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('网关使用中'), findsNothing);
    await tapKey(tester, 'provider-${catalogBeforeRename.providers.single.id}');
    await tester.tap(find.byTooltip('编辑名称'));
    await tester.pumpAndSettle();
    final renameField = find.byKey(const ValueKey('provider-name'));
    expect(
      tester.widget<TextField>(renameField).controller!.text,
      providerName,
    );
    await tester.enterText(renameField, renamedProviderName);
    await tapKey(tester, 'save-provider-button');
    expect(find.text(renamedProviderName), findsOneWidget);
    expect(find.textContaining(apiKey, findRichText: true), findsNothing);
    final stored = preferences.getString(GatewaySettings.catalogKey)!;
    final catalog = ProviderCatalog.decode(
      jsonDecode(stored),
      allowReferences: true,
    );
    final provider = catalog.providers.single;
    final account = provider.accounts.single;
    expect(provider.name, renamedProviderName);
    expect(account.name, accountName);
    expect(account.endpoint.toString(), endpoint);
    expect(account.models, [model]);
    expect(catalog.selected, {GatewayProtocol.chat: account.id});
    expect(account.credentialId, isNotNull);
    expect(
      preferences.getKeys().map(preferences.get).join(' '),
      isNot(contains(apiKey)),
    );
    expect(await storage.readAll(), {
      'magpie.upstream.${account.credentialId}': apiKey,
    });
    // 重建应用，再次从详情打开编辑器，验证持久化配置和凭据读取。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MagpieApp(preferences: preferences));
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-providers');
    await tapKey(tester, 'provider-${provider.id}');
    expect(find.textContaining('密钥已载入'), findsOneWidget);
    await tapKey(tester, 'gateway-account-${account.id}');
    expect(find.text('协议配置'), findsOneWidget);
    expect(tester.widget<TextField>(keyField).controller!.text, isEmpty);
    final endpointField = find.byKey(const ValueKey('gateway-route-base-url'));
    expect(tester.widget<TextField>(endpointField).controller!.text, baseUrl);
    expect(find.textContaining(apiKey, findRichText: true), findsNothing);
    await tapKey(tester, 'gateway-route-save');
    expect(find.textContaining('密钥已载入'), findsOneWidget);
    expect(await storage.readAll(), {
      'magpie.upstream.${account.credentialId}': apiKey,
    });

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-gateway');
    expect(find.text('本机网关已停止'), findsOneWidget);
    expect(find.text('http://127.0.0.1:3425'), findsOneWidget);
    expect(find.text('1/5 种协议路由已配置 · 1 条就绪'), findsOneWidget);
    expect(find.textContaining(apiKey, findRichText: true), findsNothing);
  });

  testWidgets('网关页启停实际监听器并跟随控制器状态', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    // start() 等待 initialized，需在真实异步区内创建这个 Future。
    final gateway = (await tester.runAsync(() async {
      final controller = GatewayController.forTest(preferences, 0);
      await controller.initialized;
      return controller;
    }))!;
    addTearDown(gateway.dispose);
    final providerId = await gateway.createProvider(
      providerName: 'Test provider',
      accountName: 'Test account',
      protocol: GatewayProtocol.chat,
      endpoint: 'https://api.example.com/v1/chat/completions',
      apiKey: '',
      requiresKey: false,
      models: const [],
      selected: true,
    );
    expect(providerId, isNotNull);
    await tester.pumpWidget(
      GatewayScope(
        controller: gateway,
        child: const MaterialApp(
          localizationsDelegates: [MagpieL10n.delegate],
          home: Scaffold(body: GatewayPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('gateway-toggle-button'));
    expect(find.text('Local gateway is stopped'), findsOneWidget);

    const timeout = Duration(seconds: 5);
    Future<void> toggleListener(GatewayState target) async {
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final settled = Completer<GatewayState>();
        void onChange() {
          final state = gateway.state;
          if (!settled.isCompleted &&
              (state == target ||
                  (state == GatewayState.stopped && gateway.issue != null))) {
            settled.complete(state);
          }
        }

        gateway.addListener(onChange);
        try {
          await tester.tap(toggle);
          expect(
            await settled.future.timeout(timeout),
            target,
            reason: '${gateway.issue}',
          );
        } finally {
          gateway.removeListener(onChange);
        }
      });
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const ValueKey('gateway-access-token')), findsNothing);
    await toggleListener(GatewayState.running);
    expect(gateway.state, GatewayState.running);
    final address = Uri.parse('http://${gateway.address}');
    expect(address.host, '127.0.0.1');
    expect(address.port, greaterThan(0));
    expect(find.text(address.toString()), findsOneWidget);
    expect(find.text('Local gateway is running'), findsOneWidget);
    expect(gateway.accessToken, isNotEmpty);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('gateway-access-token')),
          )
          .data,
      gateway.accessToken,
    );

    Future<void> connect() async {
      final socket = await Socket.connect(
        address.host,
        address.port,
        timeout: timeout,
      );
      socket.destroy();
    }

    await tester.runAsync(connect);
    await toggleListener(GatewayState.stopped);
    expect(gateway.state, GatewayState.stopped);
    expect(find.text('Local gateway is stopped'), findsOneWidget);
    expect(gateway.accessToken, isNull);
    expect(find.byKey(const ValueKey('gateway-access-token')), findsNothing);
    await tester.runAsync(() async {
      await expectLater(connect(), throwsA(isA<SocketException>()));
    });
  });

  testWidgets('Agent 列表保留展开状态并定位到模型和接入方式', (tester) async {
    await pumpApp(tester);
    await tapKey(tester, 'nav-agents');

    final claude = find.byKey(const ValueKey('agent-name-agent-claude'));
    final claudeSummary = find.byKey(
      const ValueKey('agent-summary-agent-claude'),
    );
    final gemini = find.byKey(const ValueKey('agent-name-agent-gemini'));
    final geminiSummary = find.byKey(
      const ValueKey('agent-summary-agent-gemini'),
    );
    final model = find.byKey(const ValueKey('agent-model-agent-claude'));
    final access = find.byKey(const ValueKey('agent-access-agent-claude'));
    final more = find.byKey(const ValueKey('agents-show-more'));

    expect(model, findsOneWidget);
    expect(access, findsOneWidget);
    expect(claudeSummary, findsNothing);
    expect(find.text('Codex'), findsNothing);
    await tester.tap(claude);
    await tester.pumpAndSettle();
    expect(claudeSummary, findsOneWidget);
    await tester.tap(gemini);
    await tester.pumpAndSettle();
    expect(claudeSummary, findsNothing);
    expect(geminiSummary, findsOneWidget);

    await tester.tap(model);
    await tester.pumpAndSettle();
    final modelField = find.byKey(const ValueKey('agent-model-field'));
    expect(modelField.hitTestable(), findsOneWidget);
    await tester.enterText(modelField, 'local-config-model');
    await tester.tap(find.byKey(const ValueKey('save-agent-button')));
    await tester.pumpAndSettle();
    expect(find.text('local-config-model'), findsOneWidget);
    expect(geminiSummary, findsOneWidget);

    await tester.tap(access);
    await tester.pumpAndSettle();
    expect(find.text('SSH 远程').hitTestable(), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(model, findsOneWidget);
    expect(geminiSummary, findsOneWidget);

    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Codex'), findsOneWidget);
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-providers');
    expect(
      find.byKey(const ValueKey('provider-add')).hitTestable(),
      findsOneWidget,
    );
    await tapKey(tester, 'nav-agents');
    expect(find.text('Codex'), findsOneWidget);
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Codex'), findsNothing);
  });

  testWidgets('Agent 的供应商示例不会出现在真实供应商列表', (tester) async {
    await pumpApp(tester);
    final context = tester.element(
      find.byKey(const ValueKey('magpie-app-shell')),
    );
    final demoProviders = MagpieScope.of(context).providers;
    expect(
      demoProviders.map((provider) => provider.name),
      contains('Anthropic 官方'),
    );
    expect(GatewayScope.of(context).providers, isEmpty);

    await tapKey(tester, 'nav-providers');
    expect(find.text('还没有供应商'), findsOneWidget);
    for (final provider in demoProviders) {
      expect(find.text(provider.name), findsNothing);
    }
  });

  testWidgets('英文界面新建 Agent 后自动显示该配置', (tester) async {
    SharedPreferences.setMockInitialValues({'magpie.ui_language': 'en'});
    final preferences = await SharedPreferences.getInstance();
    await pumpApp(tester, preferences: preferences);
    await tapKey(tester, 'nav-agents');

    expect(find.text('Show 1 more'), findsOneWidget);
    expect(find.text('Not connected to Magpie'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('add-agent-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Codex'));
    await tester.pumpAndSettle();
    final name = find.widgetWithText(TextFormField, 'Codex');
    expect(name, findsOneWidget);
    await tester.ensureVisible(name);
    await tester.enterText(name, 'Build Agent');
    await tester.tap(find.byKey(const ValueKey('save-agent-button')));
    await tester.pumpAndSettle();

    expect(find.text('Build Agent').hitTestable(), findsOneWidget);
    expect(find.text('gpt-5-codex'), findsNWidgets(2));
    expect(find.text('Show less'), findsOneWidget);
    expect(find.text('Codex'), findsOneWidget);
  });

  testWidgets('Agent 编辑器支持切换配置类型与 Termux 接入方式', (tester) async {
    await pumpApp(tester);
    await tapKey(tester, 'nav-agents');

    await tester.ensureVisible(
      find.byKey(const ValueKey('agent-name-agent-claude')),
    );
    await tester.tap(find.byKey(const ValueKey('agent-name-agent-claude')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('agent-details-agent-claude')),
    );
    await tester.tap(find.byKey(const ValueKey('agent-details-agent-claude')));
    await tester.pumpAndSettle();

    expect(find.text('运行时与接入方式'), findsOneWidget);
    expect(find.text('OpenAI-compatible'), findsOneWidget);
    expect(find.text('本机 CLI'), findsOneWidget);

    await tester.tap(find.text('Termux 常驻'));
    await tester.pumpAndSettle();

    expect(find.text('Termux 不是系统级沙箱'), findsOneWidget);
    expect(find.text('查看沙箱边界'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-agent-button')));
    await tester.pumpAndSettle();
    expect(find.text('Claude Code'), findsOneWidget);
  });

  testWidgets('资源页收敛为 Skills/MCP 管理与导出，并标注演示边界', (tester) async {
    await pumpApp(tester);
    await tapKey(tester, 'nav-resources');

    expect(find.text('只做管理与导出'), findsOneWidget);
    expect(find.text('资源状态仅保存在当前演示会话'), findsOneWidget);

    await tapKey(tester, 'resource-boundary-button');
    expect(find.text('沙箱与权限边界'), findsOneWidget);
    expect(find.text('SKILLS · MCP'), findsOneWidget);
    expect(find.text('只管理与导出配置'), findsOneWidget);
    expect(find.textContaining('不会在 Android/iOS 上启动'), findsOneWidget);
    expect(find.text('Termux 不是系统级安全沙箱'), findsOneWidget);
    expect(find.text('IOS'), findsOneWidget);
    expect(find.text('当前仅展示界面状态'), findsOneWidget);
    expect(find.textContaining('不会启动进程'), findsOneWidget);
    await tester.tap(find.text('我知道了'));
    await tester.pumpAndSettle();

    // Skills: 新增并编辑演示内容。
    await tester.tap(find.byKey(const ValueKey('add-skill-button')));
    await tester.pumpAndSettle();
    expect(find.text('新增 Skill'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('skill-name-field')),
      'demo-skill',
    );
    await tester.enterText(
      find.byKey(const ValueKey('skill-description-field')),
      '演示简介',
    );
    await tester.enterText(
      find.byKey(const ValueKey('skill-instructions-field')),
      '演示内容：只在本机编辑。',
    );
    await tester.tap(find.byKey(const ValueKey('save-skill-button')));
    await tester.pumpAndSettle();
    expect(find.text('demo-skill'), findsOneWidget);

    await tester.ensureVisible(find.text('demo-skill'));
    await tester.tap(find.text('demo-skill'));
    await tester.pumpAndSettle();
    expect(find.text('演示内容：只在本机编辑。'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-skill-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('skill-description-field')),
      '更新后的简介',
    );
    await tester.tap(find.byKey(const ValueKey('save-skill-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('更新后的简介'), findsOneWidget);

    // Skills 导出：只生成内存预览，明确标注演示。
    await tester.ensureVisible(
      find.byKey(const ValueKey('export-skill-button')),
    );
    await tester.tap(find.byKey(const ValueKey('export-skill-button')));
    await tester.pumpAndSettle();
    expect(find.text('导出仍为演示'), findsOneWidget);
    expect(find.textContaining('不会写入文件'), findsOneWidget);
    expect(find.textContaining('magpie.skills.manifest'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('confirm-export-skills-button')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('未打开分享面板'), findsOneWidget);

    // MCP: stdio 只管理配置，远程 HTTP(S) 可导出。
    await tester.ensureVisible(find.byKey(const ValueKey('resource-tab-mcp')));
    await tester.tap(find.byKey(const ValueKey('resource-tab-mcp')));
    await tester.pumpAndSettle();
    expect(find.text('MCP 服务'), findsOneWidget);
    expect(find.text('github'), findsOneWidget);
    expect(find.text('不在 Android/iOS 启动'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('mcp-card-mcp-filesystem')),
        matching: find.byTooltip('stdio 仅保存配置，不在 Android/iOS 启动'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('不会运行进程'), findsOneWidget);
    expect(find.textContaining('不会发起握手'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('export-mcp-button')));
    await tester.pumpAndSettle();
    expect(find.text('仅导出远程配置，且仍为演示'), findsOneWidget);
    final manifest = tester
        .widget<SelectableText>(find.byType(SelectableText))
        .data;
    expect(manifest, contains('magpie.mcp.remote.manifest'));
    expect(manifest, contains('https://mcp.example.com/github'));
    expect(manifest, isNot(contains('stdio://workspace')));
    await tester.tap(find.byKey(const ValueKey('confirm-export-mcp-button')));
    await tester.pumpAndSettle();

    // 编辑远程 MCP 参数。
    await tester.ensureVisible(
      find.byKey(const ValueKey('mcp-card-mcp-github')),
    );
    await tester.tap(find.byKey(const ValueKey('mcp-card-mcp-github')));
    await tester.pumpAndSettle();
    expect(find.text('编辑 MCP 配置'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('mcp-name-field')),
      'github-remote',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-mcp-button')));
    await tester.tap(find.byKey(const ValueKey('save-mcp-button')));
    await tester.pumpAndSettle();
    expect(find.text('github-remote'), findsOneWidget);
  });
}
