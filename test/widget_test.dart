import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/app.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MagpieApp());
    await tester.pumpAndSettle();
  }

  Future<void> switchTab(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('概览显示演示网关，并可进入设置页', (tester) async {
    await pumpApp(tester);

    expect(find.text('概览'), findsWidgets);
    expect(find.text('未连接 Magpie 服务'), findsOneWidget);
    expect(find.text('演示状态：Gateway 运行正常'), findsOneWidget);
    expect(find.text('近期信息'), findsOneWidget);
    expect(find.text('这是一个 UI 原型'), findsOneWidget);

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

  testWidgets('四大主导航均可切换并保持页面内容', (tester) async {
    await pumpApp(tester);

    await switchTab(tester, 'nav-providers');
    expect(find.text('Anthropic 官方'), findsOneWidget);
    expect(find.text('OpenAI 兼容网关'), findsOneWidget);

    await switchTab(tester, 'nav-agents');
    expect(find.text('Claude Code'), findsOneWidget);
    expect(find.text('配置 · Claude Code'), findsOneWidget);
    expect(find.text('接入 · 本机 CLI'), findsOneWidget);

    await switchTab(tester, 'nav-resources');
    expect(find.text('Skills'), findsWidgets);
    expect(find.text('code-review'), findsOneWidget);

    await switchTab(tester, 'nav-overview');
    expect(find.text('演示状态：Gateway 运行正常'), findsOneWidget);
  });

  testWidgets('供应商详情可打开连接测试，并明确不发起网络请求', (tester) async {
    await pumpApp(tester);
    await switchTab(tester, 'nav-providers');

    await tester.tap(find.text('Anthropic 官方'));
    await tester.pumpAndSettle();

    expect(find.text('供应商详情'), findsOneWidget);
    expect(find.text('可用模型'), findsWidgets);
    expect(find.text('env:ANTHROPIC_API_KEY'), findsOneWidget);

    await tester.ensureVisible(find.text('测试连接'));
    await tester.tap(find.text('测试连接'));
    await tester.pumpAndSettle();

    expect(find.text('连接测试'), findsOneWidget);
    expect(find.text('没有发起网络请求'), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);
  });

  testWidgets('添加供应商会更新本地演示列表', (tester) async {
    await pumpApp(tester);
    await switchTab(tester, 'nav-providers');

    await tester.tap(find.byKey(const ValueKey('add-provider-button')));
    await tester.pumpAndSettle();

    expect(find.text('新增一条模型路由'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '演示供应商');
    await tester.enterText(fields.at(1), 'https://demo.example.com/v1');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('save-provider-button')));
    await tester.pumpAndSettle();

    expect(find.text('演示供应商'), findsOneWidget);
    expect(find.text('需配置'), findsWidgets);
  });

  testWidgets('Agent 编辑器支持切换配置类型与 Termux 接入方式', (tester) async {
    await pumpApp(tester);
    await switchTab(tester, 'nav-agents');

    await tester.tap(find.text('Claude Code'));
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
