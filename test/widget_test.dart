import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/app.dart';
import 'package:magpie_mobile/gateway/gateway_upstream.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> switchTab(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('概览默认停止网关，并可进入设置页', (tester) async {
    await pumpApp(tester);

    expect(find.text('概览'), findsWidgets);
    expect(find.text('http://127.0.0.1:3425'), findsOneWidget);
    expect(find.text('本机网关已停止'), findsOneWidget);
    expect(find.text('近期信息'), findsOneWidget);
    expect(find.text('其他功能仍是原型'), findsOneWidget);

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
    expect(find.bySemanticsLabel('Skills / MCP'), findsOneWidget);
    expect(find.text('Gateway'), findsOneWidget);
  });

  testWidgets('供应商主区域显示五类真实路由并从当前控制器编辑保存', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await pumpApp(tester, preferences: preferences);

    await switchTab(tester, 'nav-providers');
    for (final protocol in GatewayProtocol.values) {
      expect(
        find.byKey(ValueKey('gateway-route-${protocol.name}')),
        findsOneWidget,
      );
    }
    expect(find.text('未配置'), findsNWidgets(5));
    expect(find.text('Anthropic 官方'), findsNothing);
    expect(
      find.byKey(const ValueKey('providers-gateway-routes')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('gateway-route-chat')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('gateway-route-endpoint')),
      'https://api.example.com/v1/chat/completions',
    );
    await tester.enterText(
      find.byKey(const ValueKey('gateway-route-key')),
      'fixture-key-024',
    );
    await tester.tap(find.byKey(const ValueKey('gateway-route-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('https://api.example.com/v1/chat/completions'),
      findsOneWidget,
    );
    expect(find.text('已配置 · 已载入密钥'), findsOneWidget);
    expect(
      preferences.getString('magpie.gateway.route.chat'),
      contains('https://api.example.com/v1/chat/completions'),
    );
    expect(
      preferences.getString('magpie.gateway.route.chat'),
      isNot(contains('fixture-key-024')),
    );

    await switchTab(tester, 'nav-overview');
    expect(find.text('本机网关已停止'), findsOneWidget);
  });

  testWidgets('Agent 列表保留展开状态并定位到模型和接入方式', (tester) async {
    await pumpApp(tester);
    await switchTab(tester, 'nav-agents');

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
    await switchTab(tester, 'nav-providers');
    await switchTab(tester, 'nav-agents');
    expect(find.text('Codex'), findsOneWidget);
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Codex'), findsNothing);
  });

  testWidgets('Agent 所需的旧供应商示例保留在内部数据而不冒充真实路由', (tester) async {
    await pumpApp(tester);
    await switchTab(tester, 'nav-providers');

    expect(find.text('Anthropic 官方'), findsNothing);
    expect(
      find.byKey(const ValueKey('gateway-route-anthropic')),
      findsOneWidget,
    );
    expect(find.text('真实供应商'), findsNothing);
  });

  testWidgets('英文界面新建 Agent 后自动显示该配置', (tester) async {
    SharedPreferences.setMockInitialValues({'magpie.ui_language': 'en'});
    final preferences = await SharedPreferences.getInstance();
    await pumpApp(tester, preferences: preferences);
    await switchTab(tester, 'nav-agents');

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
    await switchTab(tester, 'nav-agents');

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
    await switchTab(tester, 'nav-resources');

    expect(find.text('只做管理与导出'), findsOneWidget);
    expect(find.textContaining('不启动 Termux 桥接'), findsOneWidget);

    await tester.ensureVisible(find.text('只做管理与导出'));
    await tester.tap(find.text('只做管理与导出'));
    await tester.pumpAndSettle();
    expect(find.text('沙箱与权限边界'), findsOneWidget);
    expect(find.text('SKILLS · MCP'), findsOneWidget);
    expect(find.text('只管理与导出配置'), findsOneWidget);
    expect(find.text('Termux 不是系统级安全沙箱'), findsOneWidget);
    expect(find.text('IOS'), findsOneWidget);
    expect(find.text('当前仅展示界面状态'), findsOneWidget);
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
    expect(find.text('更新后的简介'), findsOneWidget);

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
    expect(find.text('不在 Android/iOS 启动'), findsWidgets);
    expect(find.text('stdio 只管理配置，不在 Android/iOS 启动'), findsOneWidget);

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
